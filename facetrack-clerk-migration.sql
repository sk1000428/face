-- Migration to add Clerk user ID support to existing FaceTrack schema
-- Run this after the main schema if you already have the database set up

-- Add clerk_user_id column to students table
ALTER TABLE students ADD COLUMN IF NOT EXISTS clerk_user_id VARCHAR(255) UNIQUE;

-- Add clerk_user_id column to faculty table  
ALTER TABLE faculty ADD COLUMN IF NOT EXISTS clerk_user_id VARCHAR(255) UNIQUE;

-- Add clerk_user_id column to admins table
ALTER TABLE admins ADD COLUMN IF NOT EXISTS clerk_user_id VARCHAR(255) UNIQUE;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_students_clerk_user_id ON students(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_faculty_clerk_user_id ON faculty(clerk_user_id);
CREATE INDEX IF NOT EXISTS idx_admins_clerk_user_id ON admins(clerk_user_id);

-- Update RLS policies to work with Clerk
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Students can view own profile" ON students;
DROP POLICY IF EXISTS "Students can update own profile" ON students;

-- Create new policies for Clerk integration
CREATE POLICY "Students can view own profile" ON students
    FOR SELECT USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

CREATE POLICY "Students can update own profile" ON students
    FOR UPDATE USING (clerk_user_id = current_setting('request.jwt.claims', true)::json->>'sub');

-- Function to get current Clerk user ID
CREATE OR REPLACE FUNCTION get_current_clerk_user_id()
RETURNS TEXT AS $$
BEGIN
    RETURN current_setting('request.jwt.claims', true)::json->>'sub';
EXCEPTION
    WHEN OTHERS THEN
        RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is a student (Clerk version)
CREATE OR REPLACE FUNCTION is_student_clerk()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM students WHERE clerk_user_id = get_current_clerk_user_id()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is faculty (Clerk version)
CREATE OR REPLACE FUNCTION is_faculty_clerk()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM faculty WHERE clerk_user_id = get_current_clerk_user_id()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if current user is admin (Clerk version)
CREATE OR REPLACE FUNCTION is_admin_clerk()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM admins WHERE clerk_user_id = get_current_clerk_user_id()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Sample data for testing (optional)
-- You can insert test students with Clerk user IDs here
-- INSERT INTO students (clerk_user_id, student_id, email, full_name, status) VALUES 
-- ('user_2abc123def456', 'STU2024001', 'test@example.com', 'Test Student', 'active');

COMMENT ON COLUMN students.clerk_user_id IS 'Clerk authentication user ID';
COMMENT ON COLUMN faculty.clerk_user_id IS 'Clerk authentication user ID';
COMMENT ON COLUMN admins.clerk_user_id IS 'Clerk authentication user ID';