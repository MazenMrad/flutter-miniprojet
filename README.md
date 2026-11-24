# Assiduité — gestion centralisée des absences

Application Flutter pour étudiants, enseignants et direction. Elle couvre la consultation de l'assiduité, l'auto-déclaration, la validation, les réclamations avec escalade, l'emploi du temps, les statistiques et un journal d'audit.

## Démarrage sans backend

```bash
flutter pub get
flutter run
```

Le mode démonstration est activé automatiquement quand `SUPABASE_URL` ou `SUPABASE_KEY` est absent. Choisissez un profil sur l'écran de connexion et utilisez `demo1234`.

## Connexion à Supabase

Passer la configuration au build (jamais de clé secrète dans le code source) :

```bash
flutter run ^
  --dart-define=SUPABASE_URL=https://<ref>.supabase.co ^
  --dart-define=SUPABASE_KEY=<publishable-key>
```

Utiliser la **publishable key**, jamais la service role key. La dépendance est volontairement limitée à `supabase_flutter` v2 (`^2.9.0`) ; la v3 apporte des changements cassants.

## Base de données

1. Appliquer `supabase/migrations/202611240001_initial_schema.sql` dans le SQL Editor du projet.
2. (Optionnel, environnement de développement) appliquer `supabase/seed.sql`.
3. Créer les comptes Auth et attribuer le rôle dans **`app_metadata`**, jamais `user_metadata` (modifiable par l'utilisateur) :

```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"teacher"}'::jsonb
where email = 'teacher@demo.school';
```

Rôles acceptés : `student`, `teacher`, `director`. Créer aussi une ligne correspondante dans `public.profiles` et, pour les étudiants, dans `public.enrollments`.

### Sécurité

- RLS activée sur toutes les tables, avec des politiques par rôle et par propriétaire.
- Les privilèges de mise à jour sont limités aux colonnes métier (un enseignant ne peut pas réattribuer une déclaration à un autre étudiant).
- Les rôles sont lus depuis `app_metadata` via `public.current_app_role()` ; après une modification de rôle, l'utilisateur doit se reconnecter pour rafraîchir son JWT.
- Les triggers `audit_write()` enregistrent chaque insertion/mise à jour de déclaration, réclamation et règle dans `public.audit_log`. Le directeur voit le journal complet, les autres acteurs voient leurs propres actions.
- Les tables du schéma `public` ne sont plus exposées automatiquement à l'API Data : le migration accorde explicitement les droits à `authenticated`.

## Workflow

1. L'étudiant accède à sa séance depuis l'emploi du temps et déclare présent / absent / retard.
2. L'enseignant valide, rejette ou corrige les déclarations de ses séances.
3. L'étudiant conteste une absence validée ; l'enseignant accepte, rejette ou escalade au directeur.
4. Le directeur statue en dernier ressort, consulte les statistiques, ajuste les règles et vérifie le journal d'audit.

## Vérification

```bash
flutter analyze
flutter test
```
