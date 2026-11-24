-- Development seed data. Run after the initial migration on a local/dev project only.
-- Passwords: demo1234. Roles are stored in app_metadata, never user_metadata.

insert into auth.users (id, email, encrypted_password, email_confirmed_at, raw_app_meta_data, raw_user_meta_data)
values
  ('22222222-2222-2222-2222-222222222221', 'student@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"student"}', '{"name":"Lina Benali"}'),
  ('22222222-2222-2222-2222-222222222222', 'student2@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"student"}', '{"name":"Karim Sassi"}'),
  ('22222222-2222-2222-2222-222222222223', 'student3@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"student"}', '{"name":"Nour Gharbi"}'),
  ('33333333-3333-3333-3333-333333333331', 'teacher@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"teacher"}', '{"name":"Mme Chatbouri"}'),
  ('33333333-3333-3333-3333-333333333332', 'teacher2@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"teacher"}', '{"name":"M. Ferjani"}'),
  ('44444444-4444-4444-4444-444444444441', 'director@demo.school', crypt('demo1234', gen_salt('bf')), now(), '{"provider":"email","providers":["email"],"role":"director"}', '{"name":"M. Directeur"}')
on conflict (id) do nothing;

insert into public.school_classes (id, name, level) values
  ('11111111-1111-1111-1111-111111111111', '2nde A', 'Lycée'),
  ('11111111-1111-1111-1111-111111111112', '1ère B', 'Lycée')
on conflict (id) do nothing;

insert into public.profiles (id, full_name, role, class_id) values
  ('22222222-2222-2222-2222-222222222221', 'Lina Benali', 'student', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222', 'Karim Sassi', 'student', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222223', 'Nour Gharbi', 'student', '11111111-1111-1111-1111-111111111112'),
  ('33333333-3333-3333-3333-333333333331', 'Mme Chatbouri', 'teacher', null),
  ('33333333-3333-3333-3333-333333333332', 'M. Ferjani', 'teacher', null),
  ('44444444-4444-4444-4444-444444444441', 'M. Directeur', 'director', null)
on conflict (id) do nothing;

insert into public.enrollments (student_id, class_id) values
  ('22222222-2222-2222-2222-222222222221', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111'),
  ('22222222-2222-2222-2222-222222222223', '11111111-1111-1111-1111-111111111112')
on conflict do nothing;

insert into public.subjects (id, name, code, teacher_id) values
  ('55555555-5555-5555-5555-555555555551', 'Mathématiques', 'MATH', '33333333-3333-3333-3333-333333333331'),
  ('55555555-5555-5555-5555-555555555552', 'Français', 'FR', '33333333-3333-3333-3333-333333333331'),
  ('55555555-5555-5555-5555-555555555553', 'Physique', 'PHY', '33333333-3333-3333-3333-333333333332')
on conflict (id) do nothing;

insert into public.sessions (id, subject_id, class_id, teacher_id, starts_at, ends_at, room, status) values
  ('66666666-6666-6666-6666-666666666661', '55555555-5555-5555-5555-555555555551', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333331', current_date + interval '8 hours', current_date + interval '10 hours', 'A12', 'open'),
  ('66666666-6666-6666-6666-666666666662', '55555555-5555-5555-5555-555555555552', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333331', current_date + interval '10 hours', current_date + interval '12 hours', 'B04', 'open'),
  ('66666666-6666-6666-6666-666666666663', '55555555-5555-5555-5555-555555555553', '11111111-1111-1111-1111-111111111112', '33333333-3333-3333-3333-333333333332', current_date + interval '14 hours', current_date + interval '16 hours', 'Labo 2', 'scheduled'),
  ('66666666-6666-6666-6666-666666666664', '55555555-5555-5555-5555-555555555551', '11111111-1111-1111-1111-111111111111', '33333333-3333-3333-3333-333333333331', current_date + interval '1 day 8 hours', current_date + interval '1 day 10 hours', 'A12', 'scheduled')
on conflict (id) do nothing;

insert into public.attendance_records (id, session_id, student_id, status, source, declared_by, validation, validated_by, validated_at)
values
  ('77777777-7777-7777-7777-777777777771', '66666666-6666-6666-6666-666666666661', '22222222-2222-2222-2222-222222222221', 'present', 'student', '22222222-2222-2222-2222-222222222221', 'pending', null, null),
  ('77777777-7777-7777-7777-777777777772', '66666666-6666-6666-6666-666666666662', '22222222-2222-2222-2222-222222222221', 'absent', 'student', '22222222-2222-2222-2222-222222222221', 'approved', '33333333-3333-3333-3333-333333333331', now()),
  ('77777777-7777-7777-7777-777777777773', '66666666-6666-6666-6666-666666666661', '22222222-2222-2222-2222-222222222222', 'present', 'student', '22222222-2222-2222-2222-222222222222', 'approved', '33333333-3333-3333-3333-333333333331', now()),
  ('77777777-7777-7777-7777-777777777774', '66666666-6666-6666-6666-666666666663', '22222222-2222-2222-2222-222222222223', 'late', 'student', '22222222-2222-2222-2222-222222222223', 'pending', null, null)
on conflict (id) do nothing;

insert into public.claims (id, record_id, student_id, reason, status)
values
  ('88888888-8888-8888-8888-888888888881', '77777777-7777-7777-7777-777777777772', '22222222-2222-2222-2222-222222222221', 'Certificat médical fourni pour cette séance.', 'escalated')
on conflict (id) do nothing;

insert into public.institution_rules (key, value, description) values
  ('max_absences', '4', 'Absences tolérées par trimestre'),
  ('late_threshold_minutes', '15', 'Retard au-delà duquel une absence est relevée'),
  ('claim_delay_days', '7', 'Délai maximal pour contester une absence')
on conflict (key) do nothing;
