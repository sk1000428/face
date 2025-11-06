# FaceTrack Supabase Setup Guide

This guide will help you set up the FaceTrack database schema in Supabase.

## Prerequisites

1. A Supabase account and project
2. Access to the Supabase SQL Editor
3. Basic understanding of PostgreSQL

## Setup Steps

### Step 1: Create the Database Schema

1. Open your Supabase project dashboard
2. Navigate to the SQL Editor
3. Copy and paste the contents of `facetrack-supabase-schema.sql`
4. Run the query to create all tables, functions, and initial data

### Step 2: Set Up Authentication (Optional but Recommended)

1. Enable authentication in your Supabase project
2. Configure your preferred authentication providers (email, Google, etc.)
3. Set up user registration flow in your application

### Step 3: Link Users to Database Records

When a user registers, you'll need to create corresponding records in the `students`, `faculty`, or `admins` table. Here's an example:

```sql
-- Example: Create a student record after user registration
INSERT INTO students (
    auth_user_id,
    student_id,
    email,
    full_name,
    status
) VALUES (
    auth.uid(), -- Supabase user ID
    'STU2024001',
    'student@example.com',
    'John Doe',
    'active'
);
```

### Step 4: Apply Row Level Security Policies

1. After setting up authentication, run the contents of `facetrack-rls-policies.sql`
2. This will enable proper data access control based on user roles

### Step 5: Test the Setup

1. Create test users for different roles (student, faculty, admin)
2. Verify that RLS policies work correctly
3. Test basic CRUD operations through your application

## Database Structure Overview

### Core Tables

- **students**: Student information and profiles
- **faculty**: Faculty/teacher information
- **admins**: Administrative users
- **departments**: Academic departments
- **programs**: Degree programs (B.Tech, M.Tech, etc.)
- **subjects**: Individual courses/subjects
- **classes**: Specific class instances
- **attendance_sessions**: Individual class sessions
- **attendance_records**: Student attendance data
- **exams**: Examination information
- **exam_results**: Student exam results
- **announcements**: College announcements
- **calendar_events**: Calendar events and activities

### Key Features

- **Face Recognition Support**: Tables for storing face encodings and recognition logs
- **Flexible Settings**: User preferences and notification settings
- **Audit Logging**: Complete system activity tracking
- **Performance Optimized**: Strategic indexes for common queries
- **Scalable Design**: UUID primary keys and proper relationships

## Environment Variables

Add these to your application's environment variables:

```env
NEXT_PUBLIC_SUPABASE_URL=your_supabase_project_url
NEXT_PUBLIC_SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

## API Integration Examples

### Fetch Student Attendance

```typescript
const { data: attendance } = await supabase
  .from('student_attendance_summary')
  .select('*')
  .eq('student_id', studentId);
```

### Create Attendance Record

```typescript
const { data, error } = await supabase
  .from('attendance_records')
  .insert({
    session_id: sessionId,
    student_id: studentId,
    status: 'present',
    marking_method: 'face_recognition',
    confidence_score: 0.95
  });
```

### Fetch Upcoming Exams

```typescript
const { data: exams } = await supabase
  .from('upcoming_exams')
  .select('*')
  .order('exam_date', { ascending: true });
```

## Security Considerations

1. **Row Level Security**: Always enable RLS on sensitive tables
2. **API Keys**: Never expose service role keys in client-side code
3. **Data Validation**: Validate all inputs before database operations
4. **Regular Backups**: Set up automated database backups
5. **Monitoring**: Monitor database performance and query patterns

## Troubleshooting

### Common Issues

1. **Permission Denied**: Check RLS policies and user authentication
2. **Function Not Found**: Ensure all functions are created properly
3. **Foreign Key Violations**: Verify data relationships and constraints
4. **Performance Issues**: Check if indexes are created correctly

### Useful Queries

```sql
-- Check if RLS is enabled
SELECT schemaname, tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public';

-- View current user's role
SELECT is_student(), is_faculty(), is_admin();

-- Check attendance summary for a student
SELECT * FROM student_attendance_summary 
WHERE student_id = 'your_student_uuid';
```

## Next Steps

1. Integrate the database with your Next.js application
2. Implement face recognition functionality
3. Set up real-time subscriptions for live attendance
4. Add data visualization for attendance analytics
5. Implement notification systems

## Support

If you encounter issues:

1. Check the Supabase documentation
2. Review the SQL error messages carefully
3. Test queries in the SQL Editor first
4. Ensure proper authentication setup

## Schema Version

Current schema version: 1.0.0
Last updated: November 2024

---

**Note**: This schema is designed for educational institutions and can be customized based on specific requirements. Always test thoroughly before deploying to production.