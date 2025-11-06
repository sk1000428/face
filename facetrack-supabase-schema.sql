-- FaceTrack Student Portal - Supabase Database Schema
-- This file contains all the SQL queries to create the database structure

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- USERS AND AUTHENTICATION
-- =============================================

-- Students table
CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    clerk_user_id VARCHAR(255) UNIQUE, -- Link to Clerk auth
    auth_user_id UUID REFERENCES auth.users(id), -- Keep for backward compatibility
    student_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_image_url TEXT,
    date_of_birth DATE,
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    address TEXT,
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(20),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    graduation_date DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'graduated', 'suspended')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Faculty table
CREATE TABLE faculty (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID REFERENCES auth.users(id), -- Link to Supabase auth
    faculty_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    profile_image_url TEXT,
    department VARCHAR(100),
    designation VARCHAR(100),
    qualification VARCHAR(255),
    experience_years INTEGER,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'retired')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Admin table
CREATE TABLE admins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auth_user_id UUID REFERENCES auth.users(id), -- Link to Supabase auth
    admin_id VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    role VARCHAR(50) DEFAULT 'admin',
    permissions JSONB DEFAULT '{}',
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- ACADEMIC STRUCTURE
-- =============================================

-- Departments table
CREATE TABLE departments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL,
    description TEXT,
    head_of_department UUID REFERENCES faculty(id),
    established_year INTEGER,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Programs table (B.Tech, M.Tech, etc.)
CREATE TABLE programs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    department_id UUID REFERENCES departments(id),
    duration_years INTEGER NOT NULL,
    total_semesters INTEGER NOT NULL,
    degree_type VARCHAR(50) CHECK (degree_type IN ('undergraduate', 'postgraduate', 'diploma')),
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student enrollments
CREATE TABLE student_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id),
    program_id UUID REFERENCES programs(id),
    batch_year INTEGER NOT NULL,
    current_semester INTEGER DEFAULT 1,
    enrollment_status VARCHAR(20) DEFAULT 'active' CHECK (enrollment_status IN ('active', 'completed', 'dropped', 'suspended')),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    completion_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(student_id, program_id)
);

-- Subjects/Courses table
CREATE TABLE subjects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    credits INTEGER NOT NULL,
    semester INTEGER NOT NULL,
    program_id UUID REFERENCES programs(id),
    description TEXT,
    syllabus_url TEXT,
    is_elective BOOLEAN DEFAULT FALSE,
    prerequisites TEXT[], -- Array of subject codes
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- CLASSES AND SCHEDULING
-- =============================================

-- Academic years table
CREATE TABLE academic_years (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    year_name VARCHAR(20) NOT NULL, -- e.g., "2023-24"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'upcoming')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Semesters table
CREATE TABLE semesters (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    academic_year_id UUID REFERENCES academic_years(id),
    semester_number INTEGER NOT NULL,
    name VARCHAR(50) NOT NULL, -- e.g., "Fall 2023", "Spring 2024"
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    is_current BOOLEAN DEFAULT FALSE,
    status VARCHAR(20) DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'active', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Classes table (specific instances of subjects)
CREATE TABLE classes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID REFERENCES subjects(id),
    faculty_id UUID REFERENCES faculty(id),
    semester_id UUID REFERENCES semesters(id),
    section VARCHAR(10) NOT NULL, -- A, B, C, etc.
    room_number VARCHAR(20),
    max_capacity INTEGER DEFAULT 60,
    class_type VARCHAR(20) DEFAULT 'regular' CHECK (class_type IN ('regular', 'lab', 'tutorial', 'seminar')),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Class enrollments (students enrolled in specific classes)
CREATE TABLE class_enrollments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID REFERENCES classes(id),
    student_id UUID REFERENCES students(id),
    enrollment_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'dropped', 'completed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(class_id, student_id)
);

-- Timetable/Schedule table
CREATE TABLE schedules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID REFERENCES classes(id),
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 7), -- 1=Monday, 7=Sunday
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    room_number VARCHAR(20),
    is_recurring BOOLEAN DEFAULT TRUE,
    effective_from DATE DEFAULT CURRENT_DATE,
    effective_to DATE,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'rescheduled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- ATTENDANCE SYSTEM
-- =============================================

-- Attendance sessions (individual class sessions)
CREATE TABLE attendance_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    class_id UUID REFERENCES classes(id),
    faculty_id UUID REFERENCES faculty(id),
    session_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME,
    room_number VARCHAR(20),
    session_type VARCHAR(20) DEFAULT 'regular' CHECK (session_type IN ('regular', 'makeup', 'extra', 'exam')),
    topic_covered TEXT,
    attendance_marked BOOLEAN DEFAULT FALSE,
    face_recognition_enabled BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student attendance records
CREATE TABLE attendance_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES attendance_sessions(id),
    student_id UUID REFERENCES students(id),
    status VARCHAR(20) NOT NULL CHECK (status IN ('present', 'absent', 'late', 'excused')),
    marked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    marked_by UUID, -- Can reference faculty or admin
    marking_method VARCHAR(20) DEFAULT 'manual' CHECK (marking_method IN ('manual', 'face_recognition', 'qr_code', 'rfid')),
    confidence_score DECIMAL(5,4), -- For face recognition confidence
    face_image_url TEXT, -- URL to the captured face image
    latitude DECIMAL(10, 8), -- For location-based attendance
    longitude DECIMAL(11, 8),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(session_id, student_id)
);

-- =============================================
-- EXAMINATIONS
-- =============================================

-- Exam types table
CREATE TABLE exam_types (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL, -- Mid-term, Final, Quiz, etc.
    code VARCHAR(20) UNIQUE NOT NULL,
    weightage DECIMAL(5,2), -- Percentage weightage in final grade
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exams table
CREATE TABLE exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subject_id UUID REFERENCES subjects(id),
    exam_type_id UUID REFERENCES exam_types(id),
    semester_id UUID REFERENCES semesters(id),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    exam_date DATE NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    duration_minutes INTEGER,
    room_number VARCHAR(20),
    max_marks DECIMAL(6,2) DEFAULT 100,
    passing_marks DECIMAL(6,2) DEFAULT 40,
    instructions TEXT,
    syllabus_topics TEXT[],
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled', 'postponed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Student exam registrations
CREATE TABLE exam_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id),
    student_id UUID REFERENCES students(id),
    registration_date DATE DEFAULT CURRENT_DATE,
    seat_number VARCHAR(20),
    status VARCHAR(20) DEFAULT 'registered' CHECK (status IN ('registered', 'appeared', 'absent', 'cancelled')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(exam_id, student_id)
);

-- Exam results
CREATE TABLE exam_results (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id),
    student_id UUID REFERENCES students(id),
    marks_obtained DECIMAL(6,2),
    grade VARCHAR(5),
    grade_points DECIMAL(4,2),
    remarks TEXT,
    evaluated_by UUID REFERENCES faculty(id),
    evaluation_date DATE,
    status VARCHAR(20) DEFAULT 'pending' CHECK (status IN ('pending', 'evaluated', 'published', 'withheld')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(exam_id, student_id)
);

-- =============================================
-- ANNOUNCEMENTS AND COMMUNICATIONS
-- =============================================

-- Announcement categories
CREATE TABLE announcement_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    color VARCHAR(7) DEFAULT '#3B82F6', -- Hex color code
    icon VARCHAR(50),
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Announcements table
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    excerpt TEXT,
    category_id UUID REFERENCES announcement_categories(id),
    author_id UUID NOT NULL, -- Can be admin or faculty
    author_type VARCHAR(20) NOT NULL CHECK (author_type IN ('admin', 'faculty')),
    target_audience VARCHAR(20) DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'faculty', 'specific')),
    priority VARCHAR(20) DEFAULT 'normal' CHECK (priority IN ('low', 'normal', 'high', 'urgent')),
    publish_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE,
    is_published BOOLEAN DEFAULT FALSE,
    is_pinned BOOLEAN DEFAULT FALSE,
    attachment_urls TEXT[],
    tags TEXT[],
    view_count INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived', 'deleted')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Announcement views (track who has read what)
CREATE TABLE announcement_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    announcement_id UUID REFERENCES announcements(id),
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('student', 'faculty', 'admin')),
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(announcement_id, user_id, user_type)
);

-- =============================================
-- CALENDAR AND EVENTS
-- =============================================

-- Event categories
CREATE TABLE event_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(100) NOT NULL,
    code VARCHAR(20) UNIQUE NOT NULL,
    color VARCHAR(7) DEFAULT '#3B82F6',
    icon VARCHAR(50),
    description TEXT,
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'inactive')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Calendar events
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title VARCHAR(255) NOT NULL,
    description TEXT,
    category_id UUID REFERENCES event_categories(id),
    start_date DATE NOT NULL,
    end_date DATE,
    start_time TIME,
    end_time TIME,
    is_all_day BOOLEAN DEFAULT FALSE,
    location VARCHAR(255),
    organizer_id UUID,
    organizer_type VARCHAR(20) CHECK (organizer_type IN ('admin', 'faculty', 'student')),
    is_recurring BOOLEAN DEFAULT FALSE,
    recurrence_pattern JSONB, -- Store recurrence rules
    target_audience VARCHAR(20) DEFAULT 'all' CHECK (target_audience IN ('all', 'students', 'faculty', 'specific')),
    is_public BOOLEAN DEFAULT TRUE,
    registration_required BOOLEAN DEFAULT FALSE,
    max_participants INTEGER,
    registration_deadline DATE,
    status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'ongoing', 'completed', 'cancelled', 'postponed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event registrations
CREATE TABLE event_registrations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES calendar_events(id),
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('student', 'faculty')),
    registration_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    attendance_status VARCHAR(20) DEFAULT 'registered' CHECK (attendance_status IN ('registered', 'attended', 'absent', 'cancelled')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(event_id, user_id, user_type)
);

-- =============================================
-- USER SETTINGS AND PREFERENCES
-- =============================================

-- User settings
CREATE TABLE user_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('student', 'faculty', 'admin')),
    setting_key VARCHAR(100) NOT NULL,
    setting_value JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, user_type, setting_key)
);

-- Notification preferences
CREATE TABLE notification_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL,
    user_type VARCHAR(20) NOT NULL CHECK (user_type IN ('student', 'faculty', 'admin')),
    attendance_alerts BOOLEAN DEFAULT TRUE,
    exam_reminders BOOLEAN DEFAULT TRUE,
    college_announcements BOOLEAN DEFAULT TRUE,
    email_notifications BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    push_notifications BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, user_type)
);

-- =============================================
-- FACE RECOGNITION DATA
-- =============================================

-- Face recognition profiles
CREATE TABLE face_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id UUID REFERENCES students(id) UNIQUE,
    face_encoding BYTEA NOT NULL, -- Encoded face data
    face_images TEXT[], -- URLs to face images used for training
    confidence_threshold DECIMAL(5,4) DEFAULT 0.8000,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Face recognition logs
CREATE TABLE face_recognition_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID REFERENCES attendance_sessions(id),
    student_id UUID REFERENCES students(id),
    captured_image_url TEXT,
    confidence_score DECIMAL(5,4),
    recognition_status VARCHAR(20) CHECK (recognition_status IN ('success', 'failed', 'low_confidence', 'multiple_faces', 'no_face')),
    processing_time_ms INTEGER,
    device_info JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- SYSTEM LOGS AND AUDIT
-- =============================================

-- System audit logs
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID,
    user_type VARCHAR(20) CHECK (user_type IN ('student', 'faculty', 'admin', 'system')),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(100),
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- INDEXES FOR PERFORMANCE
-- =============================================

-- Students indexes
CREATE INDEX idx_students_student_id ON students(student_id);
CREATE INDEX idx_students_email ON students(email);
CREATE INDEX idx_students_status ON students(status);

-- Attendance indexes
CREATE INDEX idx_attendance_records_session_id ON attendance_records(session_id);
CREATE INDEX idx_attendance_records_student_id ON attendance_records(student_id);
CREATE INDEX idx_attendance_records_status ON attendance_records(status);
CREATE INDEX idx_attendance_sessions_date ON attendance_sessions(session_date);
CREATE INDEX idx_attendance_sessions_class_id ON attendance_sessions(class_id);

-- Exam indexes
CREATE INDEX idx_exams_date ON exams(exam_date);
CREATE INDEX idx_exams_subject_id ON exams(subject_id);
CREATE INDEX idx_exam_results_student_id ON exam_results(student_id);

-- Announcement indexes
CREATE INDEX idx_announcements_publish_date ON announcements(publish_date);
CREATE INDEX idx_announcements_category_id ON announcements(category_id);
CREATE INDEX idx_announcements_status ON announcements(status);

-- Calendar indexes
CREATE INDEX idx_calendar_events_start_date ON calendar_events(start_date);
CREATE INDEX idx_calendar_events_category_id ON calendar_events(category_id);

-- =============================================
-- TRIGGERS FOR UPDATED_AT
-- =============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to all tables with updated_at column
CREATE TRIGGER update_students_updated_at BEFORE UPDATE ON students FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_faculty_updated_at BEFORE UPDATE ON faculty FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_admins_updated_at BEFORE UPDATE ON admins FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_departments_updated_at BEFORE UPDATE ON departments FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_programs_updated_at BEFORE UPDATE ON programs FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_classes_updated_at BEFORE UPDATE ON classes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendance_sessions_updated_at BEFORE UPDATE ON attendance_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_attendance_records_updated_at BEFORE UPDATE ON attendance_records FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_exams_updated_at BEFORE UPDATE ON exams FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_calendar_events_updated_at BEFORE UPDATE ON calendar_events FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- =============================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================

-- Enable RLS on sensitive tables
ALTER TABLE students ENABLE ROW LEVEL SECURITY;
ALTER TABLE faculty ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE exam_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (customize based on your authentication system)
-- Note: These policies assume you'll link Supabase auth.users to your students table
-- You may need to adjust based on your authentication implementation

-- Students can only see their own data
-- CREATE POLICY students_own_data ON students FOR ALL USING (
--     auth.uid() IN (SELECT auth_user_id FROM students WHERE id = students.id)
-- );

-- Students can only see their own attendance records  
-- CREATE POLICY students_own_attendance ON attendance_records FOR SELECT USING (
--     student_id IN (
--         SELECT id FROM students WHERE auth_user_id = auth.uid()
--     )
-- );

-- Uncomment and modify these policies after setting up your authentication flow

-- =============================================
-- SAMPLE DATA INSERTION
-- =============================================

-- Insert sample departments
INSERT INTO departments (name, code, description) VALUES
('Computer Science & Engineering', 'CSE', 'Department of Computer Science and Engineering'),
('Electronics & Communication', 'ECE', 'Department of Electronics and Communication Engineering'),
('Mechanical Engineering', 'ME', 'Department of Mechanical Engineering'),
('Mathematics', 'MATH', 'Department of Mathematics');

-- Insert sample programs
INSERT INTO programs (name, code, department_id, duration_years, total_semesters, degree_type) VALUES
('Bachelor of Technology in Computer Science', 'BTECH-CSE', (SELECT id FROM departments WHERE code = 'CSE'), 4, 8, 'undergraduate'),
('Bachelor of Technology in Electronics', 'BTECH-ECE', (SELECT id FROM departments WHERE code = 'ECE'), 4, 8, 'undergraduate');

-- Insert sample exam types
INSERT INTO exam_types (name, code, weightage) VALUES
('Mid-Term Examination', 'MID', 30.00),
('Final Examination', 'FINAL', 50.00),
('Quiz', 'QUIZ', 10.00),
('Assignment', 'ASSIGN', 10.00);

-- Insert sample announcement categories
INSERT INTO announcement_categories (name, code, color, icon) VALUES
('Academic', 'ACADEMIC', '#3B82F6', 'school'),
('Examinations', 'EXAM', '#F59E0B', 'quiz'),
('Campus Events', 'EVENT', '#10B981', 'event'),
('Administration', 'ADMIN', '#6B7280', 'admin_panel_settings'),
('Scholarships', 'SCHOLAR', '#8B5CF6', 'school');

-- Insert sample event categories
INSERT INTO event_categories (name, code, color, icon) VALUES
('Academic', 'ACADEMIC', '#F97316', 'school'),
('Holidays', 'HOLIDAY', '#22C55E', 'celebration'),
('Campus Events', 'CAMPUS', '#8B5CF6', 'event'),
('Workshops', 'WORKSHOP', '#3B82F6', 'build'),
('Sports', 'SPORTS', '#EF4444', 'sports');

-- =============================================
-- VIEWS FOR COMMON QUERIES
-- =============================================

-- View for student attendance summary
CREATE VIEW student_attendance_summary AS
SELECT 
    s.id as student_id,
    s.student_id as student_number,
    s.full_name,
    sub.name as subject_name,
    sub.code as subject_code,
    COUNT(ar.id) as total_sessions,
    COUNT(CASE WHEN ar.status = 'present' THEN 1 END) as present_count,
    COUNT(CASE WHEN ar.status = 'absent' THEN 1 END) as absent_count,
    COUNT(CASE WHEN ar.status = 'late' THEN 1 END) as late_count,
    ROUND(
        (COUNT(CASE WHEN ar.status = 'present' THEN 1 END) * 100.0 / NULLIF(COUNT(ar.id), 0)), 2
    ) as attendance_percentage
FROM students s
JOIN class_enrollments ce ON s.id = ce.student_id
JOIN classes c ON ce.class_id = c.id
JOIN subjects sub ON c.subject_id = sub.id
LEFT JOIN attendance_sessions ats ON c.id = ats.class_id
LEFT JOIN attendance_records ar ON ats.id = ar.session_id AND s.id = ar.student_id
WHERE s.status = 'active'
GROUP BY s.id, s.student_id, s.full_name, sub.name, sub.code;

-- View for upcoming exams
CREATE VIEW upcoming_exams AS
SELECT 
    e.id,
    e.title,
    s.name as subject_name,
    s.code as subject_code,
    et.name as exam_type,
    e.exam_date,
    e.start_time,
    e.end_time,
    e.room_number,
    e.max_marks,
    (e.exam_date - CURRENT_DATE) as days_remaining
FROM exams e
JOIN subjects s ON e.subject_id = s.id
JOIN exam_types et ON e.exam_type_id = et.id
WHERE e.exam_date >= CURRENT_DATE
AND e.status = 'scheduled'
ORDER BY e.exam_date, e.start_time;

-- =============================================
-- FUNCTIONS FOR COMMON OPERATIONS
-- =============================================

-- Function to calculate attendance percentage
CREATE OR REPLACE FUNCTION calculate_attendance_percentage(
    p_student_id UUID,
    p_subject_id UUID DEFAULT NULL,
    p_start_date DATE DEFAULT NULL,
    p_end_date DATE DEFAULT NULL
)
RETURNS DECIMAL(5,2) AS $$
DECLARE
    total_sessions INTEGER;
    present_sessions INTEGER;
    attendance_percentage DECIMAL(5,2);
BEGIN
    SELECT 
        COUNT(ar.id),
        COUNT(CASE WHEN ar.status = 'present' THEN 1 END)
    INTO total_sessions, present_sessions
    FROM attendance_records ar
    JOIN attendance_sessions ats ON ar.session_id = ats.id
    JOIN classes c ON ats.class_id = c.id
    WHERE ar.student_id = p_student_id
    AND (p_subject_id IS NULL OR c.subject_id = p_subject_id)
    AND (p_start_date IS NULL OR ats.session_date >= p_start_date)
    AND (p_end_date IS NULL OR ats.session_date <= p_end_date);
    
    IF total_sessions = 0 THEN
        RETURN 0;
    END IF;
    
    attendance_percentage := (present_sessions * 100.0) / total_sessions;
    RETURN ROUND(attendance_percentage, 2);
END;
$$ LANGUAGE plpgsql;

-- Function to get student's current semester
CREATE OR REPLACE FUNCTION get_student_current_semester(p_student_id UUID)
RETURNS INTEGER AS $$
DECLARE
    current_semester INTEGER;
BEGIN
    SELECT se.current_semester
    INTO current_semester
    FROM student_enrollments se
    WHERE se.student_id = p_student_id
    AND se.enrollment_status = 'active'
    LIMIT 1;
    
    RETURN COALESCE(current_semester, 1);
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- SUPABASE SPECIFIC CONFIGURATIONS
-- =============================================

-- Function to handle new user registration
CREATE OR REPLACE FUNCTION handle_new_user() 
RETURNS TRIGGER AS $$
BEGIN
  -- This function can be used to automatically create student/faculty records
  -- when a new user signs up through Supabase Auth
  -- Customize based on your registration flow
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user registration (optional)
-- CREATE TRIGGER on_auth_user_created
--   AFTER INSERT ON auth.users
--   FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Function to get current user's student record
CREATE OR REPLACE FUNCTION get_current_student()
RETURNS students AS $$
DECLARE
    student_record students;
BEGIN
    SELECT * INTO student_record
    FROM students
    WHERE auth_user_id = auth.uid();
    
    RETURN student_record;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is a student
CREATE OR REPLACE FUNCTION is_student()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM students WHERE auth_user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is faculty
CREATE OR REPLACE FUNCTION is_faculty()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM faculty WHERE auth_user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is admin
CREATE OR REPLACE FUNCTION is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins WHERE auth_user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- COMPLETION MESSAGE
-- =============================================

-- Add a comment to indicate schema creation is complete
COMMENT ON SCHEMA public IS 'FaceTrack Student Portal Database Schema - Created successfully';

-- Create a simple status table to track schema version
CREATE TABLE schema_info (
    version VARCHAR(10) PRIMARY KEY,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    description TEXT
);

INSERT INTO schema_info (version, description) VALUES 
('1.0.0', 'Initial FaceTrack database schema with all core tables and features');