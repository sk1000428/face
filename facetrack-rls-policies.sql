-- FaceTrack Row Level Security (RLS) Policies
-- Apply these policies after setting up your Supabase authentication flow

-- =============================================
-- STUDENTS TABLE POLICIES
-- =============================================

-- Students can view and update their own profile
CREATE POLICY "Students can view own profile" ON students
    FOR SELECT USING (auth_user_id = auth.uid());

CREATE POLICY "Students can update own profile" ON students
    FOR UPDATE USING (auth_user_id = auth.uid());

-- Faculty and admins can view all student profiles
CREATE POLICY "Faculty can view student profiles" ON students
    FOR SELECT USING (is_faculty() OR is_admin());

-- =============================================
-- ATTENDANCE RECORDS POLICIES
-- =============================================

-- Students can only view their own attendance records
CREATE POLICY "Students can view own attendance" ON attendance_records
    FOR SELECT USING (
        student_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )
    );

-- Faculty can view attendance for their classes
CREATE POLICY "Faculty can view class attendance" ON attendance_records
    FOR ALL USING (
        is_faculty() AND EXISTS (
            SELECT 1 FROM attendance_sessions ats
            JOIN classes c ON ats.class_id = c.id
            JOIN faculty f ON c.faculty_id = f.id
            WHERE ats.id = attendance_records.session_id
            AND f.auth_user_id = auth.uid()
        )
    );

-- Admins can view all attendance records
CREATE POLICY "Admins can view all attendance" ON attendance_records
    FOR ALL USING (is_admin());

-- =============================================
-- EXAM RESULTS POLICIES
-- =============================================

-- Students can only view their own exam results
CREATE POLICY "Students can view own results" ON exam_results
    FOR SELECT USING (
        student_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )
    );

-- Faculty can view results for exams they conduct
CREATE POLICY "Faculty can view their exam results" ON exam_results
    FOR ALL USING (
        is_faculty() AND EXISTS (
            SELECT 1 FROM exams e
            JOIN subjects s ON e.subject_id = s.id
            JOIN classes c ON s.id = c.subject_id
            JOIN faculty f ON c.faculty_id = f.id
            WHERE e.id = exam_results.exam_id
            AND f.auth_user_id = auth.uid()
        )
    );

-- Admins can view all exam results
CREATE POLICY "Admins can view all results" ON exam_results
    FOR ALL USING (is_admin());

-- =============================================
-- USER SETTINGS POLICIES
-- =============================================

-- Users can only access their own settings
CREATE POLICY "Users can manage own settings" ON user_settings
    FOR ALL USING (
        (user_type = 'student' AND user_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )) OR
        (user_type = 'faculty' AND user_id IN (
            SELECT id FROM faculty WHERE auth_user_id = auth.uid()
        )) OR
        (user_type = 'admin' AND user_id IN (
            SELECT id FROM admins WHERE auth_user_id = auth.uid()
        ))
    );

-- =============================================
-- NOTIFICATION PREFERENCES POLICIES
-- =============================================

-- Users can only access their own notification preferences
CREATE POLICY "Users can manage own notifications" ON notification_preferences
    FOR ALL USING (
        (user_type = 'student' AND user_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )) OR
        (user_type = 'faculty' AND user_id IN (
            SELECT id FROM faculty WHERE auth_user_id = auth.uid()
        )) OR
        (user_type = 'admin' AND user_id IN (
            SELECT id FROM admins WHERE auth_user_id = auth.uid()
        ))
    );

-- =============================================
-- ANNOUNCEMENTS POLICIES
-- =============================================

-- All authenticated users can view published announcements
CREATE POLICY "Users can view published announcements" ON announcements
    FOR SELECT USING (
        is_published = true AND 
        status = 'published' AND
        (expiry_date IS NULL OR expiry_date > NOW())
    );

-- Faculty and admins can create announcements
CREATE POLICY "Faculty can create announcements" ON announcements
    FOR INSERT WITH CHECK (is_faculty() OR is_admin());

-- Authors can update their own announcements
CREATE POLICY "Authors can update own announcements" ON announcements
    FOR UPDATE USING (
        (author_type = 'faculty' AND author_id IN (
            SELECT id FROM faculty WHERE auth_user_id = auth.uid()
        )) OR
        (author_type = 'admin' AND author_id IN (
            SELECT id FROM admins WHERE auth_user_id = auth.uid()
        ))
    );

-- =============================================
-- CALENDAR EVENTS POLICIES
-- =============================================

-- All users can view public events
CREATE POLICY "Users can view public events" ON calendar_events
    FOR SELECT USING (is_public = true);

-- Users can view events they organized
CREATE POLICY "Users can view own events" ON calendar_events
    FOR SELECT USING (
        (organizer_type = 'student' AND organizer_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )) OR
        (organizer_type = 'faculty' AND organizer_id IN (
            SELECT id FROM faculty WHERE auth_user_id = auth.uid()
        )) OR
        (organizer_type = 'admin' AND organizer_id IN (
            SELECT id FROM admins WHERE auth_user_id = auth.uid()
        ))
    );

-- Faculty and admins can create events
CREATE POLICY "Faculty can create events" ON calendar_events
    FOR INSERT WITH CHECK (is_faculty() OR is_admin());

-- Event organizers can update their events
CREATE POLICY "Organizers can update events" ON calendar_events
    FOR UPDATE USING (
        (organizer_type = 'faculty' AND organizer_id IN (
            SELECT id FROM faculty WHERE auth_user_id = auth.uid()
        )) OR
        (organizer_type = 'admin' AND organizer_id IN (
            SELECT id FROM admins WHERE auth_user_id = auth.uid()
        ))
    );

-- =============================================
-- FACE PROFILES POLICIES
-- =============================================

-- Students can only access their own face profile
CREATE POLICY "Students can access own face profile" ON face_profiles
    FOR ALL USING (
        student_id IN (
            SELECT id FROM students WHERE auth_user_id = auth.uid()
        )
    );

-- Faculty and admins can view face profiles (for attendance purposes)
CREATE POLICY "Faculty can view face profiles" ON face_profiles
    FOR SELECT USING (is_faculty() OR is_admin());

-- =============================================
-- AUDIT LOGS POLICIES
-- =============================================

-- Only admins can view audit logs
CREATE POLICY "Only admins can view audit logs" ON audit_logs
    FOR SELECT USING (is_admin());

-- =============================================
-- HELPER FUNCTIONS FOR POLICIES
-- =============================================

-- Function to check if user can access specific class data
CREATE OR REPLACE FUNCTION can_access_class_data(class_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Students can access if they're enrolled in the class
    IF is_student() THEN
        RETURN EXISTS (
            SELECT 1 FROM class_enrollments ce
            JOIN students s ON ce.student_id = s.id
            WHERE ce.class_id = class_uuid
            AND s.auth_user_id = auth.uid()
        );
    END IF;
    
    -- Faculty can access if they teach the class
    IF is_faculty() THEN
        RETURN EXISTS (
            SELECT 1 FROM classes c
            JOIN faculty f ON c.faculty_id = f.id
            WHERE c.id = class_uuid
            AND f.auth_user_id = auth.uid()
        );
    END IF;
    
    -- Admins can access all classes
    IF is_admin() THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user can access specific subject data
CREATE OR REPLACE FUNCTION can_access_subject_data(subject_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    -- Students can access if they're enrolled in any class of this subject
    IF is_student() THEN
        RETURN EXISTS (
            SELECT 1 FROM class_enrollments ce
            JOIN classes c ON ce.class_id = c.id
            JOIN students s ON ce.student_id = s.id
            WHERE c.subject_id = subject_uuid
            AND s.auth_user_id = auth.uid()
        );
    END IF;
    
    -- Faculty can access if they teach any class of this subject
    IF is_faculty() THEN
        RETURN EXISTS (
            SELECT 1 FROM classes c
            JOIN faculty f ON c.faculty_id = f.id
            WHERE c.subject_id = subject_uuid
            AND f.auth_user_id = auth.uid()
        );
    END IF;
    
    -- Admins can access all subjects
    IF is_admin() THEN
        RETURN TRUE;
    END IF;
    
    RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- INSTRUCTIONS
-- =============================================

/*
To apply these policies:

1. First, run the main schema file (facetrack-supabase-schema.sql)
2. Set up your Supabase authentication and user registration flow
3. Ensure users are properly linked to students/faculty/admins tables via auth_user_id
4. Then run this RLS policies file
5. Test the policies with different user roles

Note: You may need to adjust these policies based on your specific 
authentication flow and business requirements.
*/