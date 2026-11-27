UPDATE users
SET must_change_password = TRUE,
    updated_at = NOW()
WHERE LOWER(username) = 'admin'
  AND role = 'owner'
  AND created_by IS NULL
  AND must_change_password = FALSE;
