-- SECURITY NOTICE: Passwords are encrypted and cannot be viewed via SQL.
-- This query lists all users with their roles and phone numbers (usernames).

SELECT 
    phone_number as "Tài Khoản (SĐT)",
    full_name as "Họ Tên",
    role as "Quyền Hạn",
    status as "Trạng Thái",
    created_at as "Ngày Tạo"
FROM 
    public.profiles
ORDER BY 
    role, created_at DESC;

-- Note: Default password for setup users was likely '123456' unless changed.
