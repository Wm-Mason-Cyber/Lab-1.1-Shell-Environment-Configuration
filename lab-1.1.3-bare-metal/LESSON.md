# ⚡ L1.1.3 Bare Metal, High Stakes

**Risk Level:** High (Persistent Workstation Environmental Consequences)

**Objective:** Manage configuration states within your actual host shell space. A syntax error or accidental secret disclosure here directly impacts your local host performance or leaks your true workstation access parameters.

**Environment:** Local Workstation Native Shell Profile (`Debian/Fedora`)
<details>
<summary>The Architecture: Local Bare-Metal Testing & CI/CD Automation</summary>

Your syllabus explicitly states that in Module 0, students configure a **bare-metal dual-boot Linux ecosystem** where they have `sudo` access.

* If you host a central container or VM where everyone logs in as a basic user, you are stripping away their administrative privileges and testing a completely different environment than the one they just spent two weeks partitioning and installing.  
    
* Because Lab 1.1 targets **Shell Environment Configuration** (`PATH`, local flags, and scopes), the test *must* evaluate the actual configuration files on their physical machines.

##### Recommended Workflow

1\. **Local Evaluation (Student):** Students run a provided bash script directly on their bare-metal Linux partition to check their progress.

2\. **Central Collection (Teacher):** Since your lab operates under strict local containment or an air-gapped network, you can host a lightweight, local Git server (like **Gitea**) on a desktop in your classroom. When students push their code to this local server, an automated runner executes the tests and logs the grades, or you can run a script to pull their repos locally and parse the results into a CSV for your grade book.

##### Lab 1.1 Automation Architecture

Here is how the system components interact on your isolated lab network:

```
+------------------------------------------------------------------------+
|                      STUDENT WORKSTATION (BARE-METAL)                  |
|                                                                        |
|  1. Modifies ~/.bashrc  -->  2. Runs 'pytest'  -->  3. 'git push' to   |
|     (Adds PATH/flags)        (Instant Feedback)         Local Server   |
+------------------------------------------------------------------------+
                                                              |
                                                              v
                                             +-------------------------------+
                                             |     INSTRUCTOR TECH STACK     |
                                             |                               |
                                             |  4. Local Gitea/Git Server    |
                                             |  5. Grading script parses     |
                                             |     results into Gradebook    |
                                             +-------------------------------+

```
</details>

## Mission Overview

You will step outside the safety of throwaway folders. You will manipulate your native operating system's environment profiles (`.bashrc` / `.zshrc`) to structure persistent variables, simulate a credential management failure by staging a cleartext access key, and build local automation to audit and defend your host machine from secret exposure.

### Step 1: Interrogating the True Host Space

1. Open your terminal natively on your Linux system partition.  
2. Print your current global execution tracks (`PATH`) to see where your operating system searches for executable software code routines.  
    <details>
    <summary> Step 1.2 command hint </summary>

    <code>echo $PATH</code> will display your complete PATH variable.
         
    </details>

3. List all files inside your home user context—including hidden configuration assets.
    - *Look for files starting with a dot, such as `.bashrc` or `.bash_profile`.*
    <details>
    <summary> Step 1.3 command hint </summary>

    - <code>cd ~</code> will move you to your home directory.
    - <code>ls -la</code> lists everything in the directory, as a table.

    You can also do this in another folder, like <code>/workspace/lab1_1</code>, but that is up to you.
         
    </details>


### Step 2: Modifying Operating System Lifecycles

1. Open your configuration file (`.bashrc` or equivalent) using a command-line text editor.     
    <details>
    <summary> Step 2.1 command hint </summary>
        
    - <code>nano ~/.bashrc</code> is probably the cleanest way to do this.
    > [!TIP] There are many CLI text editors beyond <code>nano</code> as well.
    
    </details>

2. Scroll to the very bottom of the file. Carefully inject an explicit environmental variable definition:

```shell
export ARCHITECT_CLEARANCE="LEVEL_4_HOST"
```

3. Save and close the text tool.  
    <details>
    <summary> Step 2.3 command hint: save and exit in <code>nano</code></summary>

    - To exit, you press <code>CTRL + x</code> at any time.
    - If there are changes in the file, nano will ask if you want to save/write them: type <code>y</code>.
    - Then nano will verify the filename, unless you want to change it, just press <code>ENTER</code>.

    </details>

4. Run an inspection command to check your new variable. Notice it outputs *nothing*\! Why? The current running shell process has not loaded the revised profile state yet.  
    <details>
    <summary> Step 2.4 command hint: more than one way to do this one</summary>

    > [!TIP] There are many ways you can check to see if the variable is loaded. 
    
    This is not an exhaustive list of commands...
    - <code>printenv</code> displays every loaded environment variable.
    - <code>env</code> works as an more-primitive alternative to list the variables.
    - <code>printenv ARCHITECT_CLEARANCE</code> checks the value of one specific variable.
    - <code>printenv | grep ARCHITECT_CLEARANCE</code> searches for a specific variable or value.
    - <code>printenv | less</code> lets you scroll through the list manually.
    - <code>echo $ARCHITECT_CLEARANCE</code> prints a single variable's value using the shell.
    - <code>declare -p | grep "ARCHITECT_CLEARANCE"</code> declare is a builtin bash utility that lets you use variables with types.

    </details>

5. Force-refresh your active terminal process space to ingest the configuration change without restarting the machine.

To force the active shell process to immediately read the revised state configuration:

```shell
source .bashrc
echo $ARCHITECT_CLEARANCE
```
6. Finally, run an inspection command again to see that the new variable has been loaded correctly.

### Step 3: Simulating a Severe Leakage Incident

1. Create a workspace folder named `host-deployment-project` and initialize it with an active tracking tree (`git init`).  
2. Save your progress from Step 2 above, so it will be submitted for auto-grade:

```shell
# inside `host-deployment-project/` after sourcing .bashrc:
printenv ARCHITECT_CLEARANCE > env_evidence.txt
git add env_evidence.txt
git commit -m "evidence: export ARCHITECT_CLEARANCE"
```

3. Create a file named `.env`. This file is meant to house application parameters locally.  
4. Inside `.env`, type a mock production access credential sequence:

```
AWS_SECRET_ACCESS_KEY="super_secret_high_privilege_production_token_xyz123"
DATABASE_ROOT_PASSWORD="admin_host_system_password"
```

5. Save the file.  
6. **The Common Mistake:** Accidentally stage *all* tracking assets inside your project tree for an upcoming push.

```shell
git add .
git status
```

*Notice that your sensitive `.env` asset is highlighted in green, meaning it is staged to be baked forever into the immutable timeline logs.*

### Step 4: Engineering an Automation Defense Shield

Before you accidentally commit this secret block, you will construct a programmatic block shield.

1. Create a file named `.gitignore` in the root folder of your project.  
2. Edit the file to contain exactly one word:

```
.env
```

3. Save the `.gitignore` file. Run your status checking tool again. Notice that the `.env` file is *still* staged for execution\! Why? Once a file is tracked or explicitly staged, adding it to `.gitignore` does not retroactively remove it.  
4. Programmatically unstage the file, wipe it from the staging cache, and observe how `.gitignore` shields your project from future leakage attempts.

To completely unstage and strip the cache tracking parameters from `.env`:

```shell
git rm --cached .env
git status
```

*If configured correctly, `.env` will completely disappear from your tracking list, and only `.gitignore` will be ready to log into history.*

## Self-Grade and Submit

Students will be able to run the grading script repeatedly, to verify that they have gotten everything correct. If you’re a nervous-nelly, read this section to the end before engaging. 

If everything is configured correctly (check with the teacher, this is a bit of a fancy trick…) then you should be able to see your grade in the ACT Runner results on Gitea. Whenever you push your code up to the server, it will automatically reevaluate your newest submission. And (by the nature of the goals here) you will be able to keep working to improve your grade on this lab for everything *except for one mistake*: if you EVER commit & push the `.env` file to the Gitea repo, you can never get points back for that mistake. ← Just like a committed API Key can never be removed from a git tree.

Push your work to the Gitea repository to submit for autograde (run from within `host-deployment-project`):

```shell
# you will need to update `GITEA_IP` and `YOUR_USERNAME` appropriately
git remote add origin http://GITEA_IP:3000/lab-1-1/YOUR_USERNAME
git push -u origin main
```

You should be able to see your grading results at:  `http://GITEA IP:3000/lab-1-1/YOUR_USERNAME/actions`

To find Your grades:

1. Replace `GITEA_IP` and `YOUR_USERNAME` in the URL with the correct IP address and your actual Gitea username, respectively.  
2. Click on the top workflow run labeled "`Lab 1.1.3 — Automated Grading`".  
3. Click the "`Grade — {username}`" job on the left panel to view the live execution logs and final score.

—

If that still doesn’t sit well with you, you are welcome to download and run the grader script locally in a `curl-pipe-bash` format before touching Gitea:

```shell
curl https://raw.githubusercontent.com/Wm-Mason-Cyber/Lab-1.1-Shell-Environment-Configuration/refs/heads/main/lab-1.1.3-bare-metal/ci/grade_checks.sh | bash
```

And if you see: `[4] .env never committed --- FAIL` you could restart this L1.1.3 lab (before pushing to Gitea) and have a chance to recover that missed point.   