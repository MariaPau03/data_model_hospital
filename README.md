# Clinical Trials Support Database — Data Model (README)

This README describes the **logical data model** for a hospital clinical-trials support service.

It covers:
- Clinical studies (name/description/contact/lab)
- Application users and roles (Admin / Supervisor / Data entry)
- **Pseudonymized** study participants (no direct identity in this DB)
- Clinical data (single items + files)
- Longitudinal follow-up via visits
- Variable catalog (flexible labels but from a controlled set)

> **Important legal note (pseudonymization):**  
> This database stores **only pseudonymized identifiers** (e.g., `participant_code`).  
> The mapping to real patient identity must be stored in a **separate Identity DB**.

---

## 1) Line types in MySQL Workbench (dashed vs solid)

### Dashed line = Non-identifying relationship (recommended here)
Use **dashed** lines when:
- The child table has its own primary key (e.g., `visit_id`)
- The FK to the parent is **not part of** the child’s primary key

This is the most common design pattern and avoids FK “explosion” in Workbench.

### Solid line = Identifying relationship (rarely needed here)
Use **solid** lines when:
- The child table’s primary key **includes** the parent key  
  (typical for junction tables if you set PK = `(parent_id, other_id)`)

In this model, you can still use dashed lines everywhere and remain conceptually correct.
Teachers usually care about **cardinality and correct FK direction**, not Workbench’s line style.

---

## 2) Tables, keys, and purpose

### 2.1 Study metadata

#### `LAB`
**Purpose:** Laboratory/unit responsible for studies.

- **PK:** `lab_id`
- Attributes: `name`, `department`, `email`, `phone`

**Relationships:**
- `LAB (1) ──< (N) STUDY`  *(dashed 1:N)*

---

#### `CONTACT`
**Purpose:** Contact person for a study (can be internal or external).

- **PK:** `contact_id`
- Attributes: `name`, `email`, `phone`, `organization`

**Relationships:**
- `CONTACT (1) ──< (N) STUDY` *(dashed 1:N)*

---

#### `STUDY`
**Purpose:** Clinical study/trial definition.

- **PK:** `study_id`
- **FKs:**
  - `lab_id` → `LAB.lab_id`
  - `primary_contact_id` → `CONTACT.contact_id`
- Attributes: `study_code` (unique), `name`, `description`

**Relationships:**
- `LAB (1) ──< (N) STUDY` *(dashed 1:N)*
- `CONTACT (1) ──< (N) STUDY` *(dashed 1:N)*
- `STUDY (1) ──< (N) PARTICIPANT` *(dashed 1:N)*
- `STUDY (1) ──< (N) STUDY_VARIABLE` *(dashed 1:N)*

---

### 2.2 Pseudonymized participants & visits (longitudinal)

#### `PARTICIPANT`
**Purpose:** Participant enrolled in a specific study, **pseudonymized**.

- **PK:** `participant_id`
- **FK:**
  - `study_id` → `STUDY.study_id`
- Attributes: `participant_code` (generated; unique per study), `enrollment_date`, `status`

**Key constraints (recommended):**
- Unique: `(study_id, participant_code)` (participant codes are unique per study)

**Relationships:**
- `STUDY (1) ──< (N) PARTICIPANT` *(dashed 1:N)*
- `PARTICIPANT (1) ──< (N) VISIT` *(dashed 1:N)*

---

#### `VISIT`
**Purpose:** Hospital visit / timepoint for longitudinal follow-up.

- **PK:** `visit_id`
- **FK:**
  - `participant_id` → `PARTICIPANT.participant_id`
- Attributes: `visit_date`, `visit_label` (Baseline/Month3/etc), `visit_number`

**Relationships:**
- `PARTICIPANT (1) ──< (N) VISIT` *(dashed 1:N)*
- `VISIT (1) ──< (N) OBSERVATION` *(dashed 1:N; optional if observation can exist without visit)*
- `VISIT (1) ──< (N) FILE_ASSET` *(dashed 1:N; optional if file can exist without visit)*

> **Longitudinal data:**  
> Because data links to `VISIT`, and `VISIT` has `visit_date`, the model supports repeated measures over time.

---

### 2.3 Controlled variable catalog (flexible labels)

#### `VARIABLE`
**Purpose:** Controlled “dictionary” of variables that can be collected across studies.

- **PK:** `variable_id`
- Attributes:
  - `code` (unique, e.g., `AGE_YEARS`, `SBP_MM_HG`, `MRI_T1`)
  - `display_name`
  - `data_kind` (SCALAR/TEXT/DATE/BOOLEAN/CATEGORICAL/FILE)
  - `unit`

**Relationships:**
- `VARIABLE (1) ──< (N) STUDY_VARIABLE` *(dashed 1:N)*
- `VARIABLE (1) ──< (N) OBSERVATION` *(dashed 1:N)*
- `VARIABLE (1) ──< (N) FILE_ASSET` *(dashed 1:N)*

---

#### `STUDY_VARIABLE`
**Purpose:** Defines which variables are used in each study + constraints.

- **PK:** (recommended composite) `(study_id, variable_id)`  
  *(or a surrogate PK, but composite is typical for junction tables)*
- **FKs:**
  - `study_id` → `STUDY.study_id`
  - `variable_id` → `VARIABLE.variable_id`
- Attributes: `is_longitudinal`, `is_required`

**Relationships:**
- `STUDY (1) ──< (N) STUDY_VARIABLE` *(dashed 1:N)*
- `VARIABLE (1) ──< (N) STUDY_VARIABLE` *(dashed 1:N)*

**Meaning:** This provides the “known set of variables” requirement:
- Variables are not hard-coded into the schema,
- but every data value must refer to a variable from this catalog.

---

### 2.4 Clinical data storage (items + files)

#### `OBSERVATION`
**Purpose:** One recorded clinical value (e.g., age, blood pressure).

**Minimal normalized design (recommended for class):**
- **PK:** `observation_id`
- **FKs:**
  - `visit_id` → `VISIT.visit_id`
  - `variable_id` → `VARIABLE.variable_id`
  - (recommended) `entered_by_user_id` → `app_user.user_id`
- Attributes: `observed_at`, `value`

**Relationships:**
- `VISIT (1) ──< (N) OBSERVATION` *(dashed 1:N)*
- `VARIABLE (1) ──< (N) OBSERVATION` *(dashed 1:N)*
- `app_user (1) ──< (N) OBSERVATION` *(dashed 1:N; traceability)*

**Do we need `participant_id` here?**
- **Not strictly necessary**, because: `OBSERVATION → VISIT → PARTICIPANT`
- **Optional improvement:** add `participant_id` for performance/reporting, but then enforce consistency (avoid mismatches). For a teacher exercise, the fully normalized approach is usually preferred.

---

#### `FILE_ASSET`
**Purpose:** Metadata for clinical files (imaging, sequencing, etc.).
Actual files are stored outside the DB; the DB stores metadata + a pointer (`storage_uri`).

**Minimal normalized design:**
- **PK:** `file_id`
- **FKs:**
  - `visit_id` → `VISIT.visit_id` *(if file tied to a visit)*
  - `variable_id` → `VARIABLE.variable_id` *(must represent a FILE-type variable)*
  - (recommended) `entered_by_user_id` → `app_user.user_id`
- Attributes: `file_name`, `storage_uri`

**Relationships:**
- `VISIT (1) ──< (N) FILE_ASSET` *(dashed 1:N)*
- `VARIABLE (1) ──< (N) FILE_ASSET` *(dashed 1:N)*
- `app_user (1) ──< (N) FILE_ASSET` *(dashed 1:N; traceability)*

**Optional improvement:** add `participant_id` for fast filtering and to allow files not tied to visits.
For a strict normalized design, `visit_id` is enough to infer participant.

---

### 2.5 Users, roles, and study access

#### `app_user`
**Purpose:** Application users.

- **PK:** `user_id`
- Attributes: `email`, `full_name`, `is_active`

**Relationships:**
- `app_user (1) ──< (N) USER_STUDY_ACCESS` *(dashed 1:N)*
- `app_user (1) ──< (N) app_user_has_ROLE` *(dashed 1:N)*
- `app_user (1) ──< (N) OBSERVATION` *(entered_by, dashed 1:N)*
- `app_user (1) ──< (N) FILE_ASSET` *(entered_by, dashed 1:N)*

---

#### `ROLE`
**Purpose:** Role catalog.

- **PK:** `role_id`
- Attributes: `role_name` ∈ {ADMIN, SUPERVISOR, DATA_ENTRY}

**Relationships:**
- `ROLE (1) ──< (N) app_user_has_ROLE` *(dashed 1:N)*

---

#### `app_user_has_ROLE` (junction)
**Purpose:** Many-to-many between users and roles.

- **PK:** (recommended composite) `(user_id, role_id)`
- **FKs:**
  - `user_id` → `app_user.user_id`
  - `role_id` → `ROLE.role_id`

**Meaning:**
- A user can have multiple roles
- A role can be assigned to multiple users

---

#### `USER_STUDY_ACCESS` (junction)
**Purpose:** Assign users to studies and define access level.

- **PK:** (recommended composite) `(user_id, study_id)`
- **FKs:**
  - `user_id` → `app_user.user_id`
  - `study_id` → `STUDY.study_id`
- Attributes: `access_level` (READ/WRITE/MANAGE)

**Meaning:**
- A user can work on multiple studies
- A study can have multiple users

---

## 3) Relationship summary (cardinalities)

All listed below should be **dashed** (non-identifying) unless you intentionally set composite PKs with identifying relationships:

- `LAB 1 ──< STUDY N`
- `CONTACT 1 ──< STUDY N`
- `STUDY 1 ──< PARTICIPANT N`
- `PARTICIPANT 1 ──< VISIT N`
- `STUDY 1 ──< STUDY_VARIABLE N`
- `VARIABLE 1 ──< STUDY_VARIABLE N`
- `VISIT 1 ──< OBSERVATION N`
- `VARIABLE 1 ──< OBSERVATION N`
- `VISIT 1 ──< FILE_ASSET N`
- `VARIABLE 1 ──< FILE_ASSET N`
- `app_user 1 ──< USER_STUDY_ACCESS N`
- `STUDY 1 ──< USER_STUDY_ACCESS N`
- `app_user 1 ──< app_user_has_ROLE N`
- `ROLE 1 ──< app_user_has_ROLE N`

---

## 4) Separate Identity Database (NOT stored here)

### Identity DB (separate database / separate access controls)
**Purpose:** Store legal identity mapping, restricted.

Example table: `IDENTITY_LINK` (separate DB)
- participant_code
- patient_identifier (MRN / national id)
- patient_name, etc.

**Conceptual relationship (not enforced in this DB):**
- `PARTICIPANT.participant_code 1 — 1 IDENTITY_LINK.participant_code`

---

## 5) Notes / recommendations (for the teacher exercise)

- This design supports multiple studies, each with their own chosen variable set.
- Longitudinal data is captured through visits with dates.
- Clinical values are stored as observations; large binary content is stored externally and referenced as file assets.
- Pseudonymization is respected by separating identity mapping into a different database.

If the teacher asks why some links are dashed:
- Because tables have their own PKs and FKs are not part of the child PK (non-identifying relationships).



---

# Clinical Trials Data Management System

This project implements a robust and secure database architecture for managing clinical trials, focusing on **patient pseudonymization**, **data flexibility**, and **regulatory compliance (GDPR)**.

## 1. Project Overview

The system is designed to support multiple clinical studies simultaneously. It uses a **disjoint database architecture** to ensure that sensitive patient identity is physically separated from clinical research data.

## 2. File Manifest & Purpose

| File | Purpose |
| --- | --- |
| **`schema.sql`** | **Primary Database Engine.** Creates `clinical_trials_db`. It defines the core tables for Studies, Participants (IDs only), Visits, and the Variable Dictionary. |
| **`schema_hospital_identity.sql`** | **Security Layer.** Creates `hospital_identity_db`. This "vault" stores the mapping between the study's `pseudo_id` and the patient's real-world identity (Name, National ID). |
| **`data_inserts.sql`** | **Proof of Concept.** Populates the system with initial roles (Admin, Supervisor), a sample study, clinical variables, and a test patient with visit records. |
| **`show_al_working_ok.sql`** | **Validation Script.** A diagnostic script that verifies database creation, lists existing records, and demonstrates the secure data-joining process. |
| **`data_model.png`** | **Visual Schema.** An Entity-Relationship Diagram (ERD) showing the logical connections between all tables. |

## 3. Key Design Features

### A. Privacy by Design (Pseudonymization)

Research personnel only access `clinical_trials_db`. They see a `pseudo_id` (e.g., Patient #1) but have no access to the patient's real name. The link to the identity is stored in a separate database intended for restricted administrative access.

### B. EAV Model for Flexibility

Instead of a rigid table structure, we use a **Variable Dictionary**. This allows adding new metrics (e.g., Glucose levels, Genomic sequences, MRI paths) simply by adding a row to the dictionary, without needing to perform `ALTER TABLE` operations.

### C. Longitudinal Tracking

The system tracks patient progress over time through the `Visits` table, allowing for multiple data entries (ClinicalData) per patient across different dates.

### D. File Management

Large datasets (Genomics/Images) are handled by storing the **absolute file paths** in the database rather than binary blobs, ensuring optimal performance and scalability.

## 4. Setup Instructions

To replicate the environment, run the following commands in your MySQL terminal:

1. **Initialize Research Database:**
```sql
source schema.sql;

```


2. **Initialize Identity Vault:**
```sql
source schema_hospital_identity.sql;

```


3. **Load Sample Data:**
```sql
source data_inserts.sql;

```


4. **Verify System:**
```sql
source show_al_working_ok.sql;

```



## 5. Database Credentials (for Evaluator)

* **Main Database:** `clinical_trials_db`
* **MySQL User:** 
* **Password:** 

---

