# GCP

|Level|Component|University Analogy|What it manages|
|---|---|---|---|
|Identity Level|Google Workspace / Cloud Identity|Student/Faculty Registry|Users (user@dpi.ait.ac.th), passwords, groups, and email.|
|Root Level|GCP Organization|The University Campus|The master container owned by your domain (dpi.ait.ac.th).|
|Grouping Level|Folders (Optional)|Departments / Labs|Logical groups (e.g., Research Projects, Production Apps).|
|Unit Level|Projects (Mandatory)|Individual Lab Rooms|APIs, permissions, quotas, and billing links.|
|Base Level|Resources|Equipment inside the room|VMs, Cloud Storage buckets, Databases, GPUs.|


# Create an Organization

Here is the summary roadmap to establish the independent GCP Organization for `**dpi.ait.ac.th**`:

### Phase 1: Claim Identity & Create the Root Organization
1. **Sign Up for Cloud Identity:**
    - Go to the **Cloud Identity Free Sign-Up Page** https://workspace.google.com/gcpidentity/signup?sku=identitybasic
    - Enter your organization details and specify `**dpi.ait.ac.th**` as your domain name.
2. **Create Root Admin Credentials:**
    - Set up your primary admin account (e.g., `admin@dpi.ait.ac.th`) and set a strong password.
    - Use an external address (like your personal Gmail) as the recovery email.
3. **Verify Domain Ownership:**
    - Google will ask you to place a temporary **TXT record** in your domain settings to verify ownership.
### Phase 2: Configure Cloud DNS & Delegation
1. **Create Managed Public Zone:**
    - Sign into the GCP Console with `admin@dpi.ait.ac.th`.
    - Navigate to **Network Services > Cloud DNS** and create a public zone for `dpi.ait.ac.th`.
2. **Hand Off NS Records to Central IT:**
    - GCP will generate **4 Name Server (NS) records** (e.g., `ns-cloud-a1.googledomains.com`).
    - Send these 4 server addresses to AIT Central IT so they can create the matching `NS` delegation record in their master DNS zone.
### Phase 3: Financial & Resource Structure
1. **Billing & Safeguards:**
    - Link a credit/procurement card under **GCP Billing**.
    - Set up **Budget Alerts** (e.g., set a threshold at $50 or $100) to receive email warnings before incurring unexpected charges.
2. **Create the Organizational Hierarchy:**
    - In **IAM & Admin > Manage Resources**, build logical folders:
        - `Shared-Services` (Projects for Cloud DNS, FreeIPA/LDAP VM, and Mail Relays)
        - `Research-Workloads` (Projects for compute, storage, and GPU clusters)
        - `Sandboxes` (Development environments for students and individual researchers)
### Phase 4: User Onboarding & Access Management
1. **Provision User Accounts:**
    - Log into the **Google Admin Console** (`admin.google.com`) using `admin@dpi.ait.ac.th`.
    - Add lab members as Cloud Identity users (e.g., `researcher@dpi.ait.ac.th`).
2. **Assign Daily Roles (IAM):**
    - Grant your daily working email (or student email) **Owner** or **Admin** privileges on relevant GCP projects.
    - Restrict access so researchers only have access to their designated projects, protecting your core DNS and server instances.