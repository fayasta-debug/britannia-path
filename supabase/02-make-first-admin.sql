-- Sustituye el correo y ejecuta en Supabase > SQL Editor.
-- Debes haber creado o registrado primero esa cuenta.
update public.profiles
set role='admin', status='active', updated_at=now()
where lower(email)=lower('TU_CORREO_AQUI');

select id,email,full_name,role,status from public.profiles
where lower(email)=lower('TU_CORREO_AQUI');
