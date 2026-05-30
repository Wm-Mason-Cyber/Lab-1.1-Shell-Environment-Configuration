# 🛑 L1.1.1 Sandbox Sandbox

**Risk Level:** Zero

**Objective:** Learn the core mechanics of tracking system state changes, generating branches, and resolving localized merge conflicts without affecting any external infrastructure.

**Environment:** Isolated Local Directory
<details>
<summary>The Sandbox Architecture: "Container-per-Student"</summary>

Instead of a single massive container where students share a space, this is a single central server running **Docker** containers for you to use for this lab.

For every student in a period, the server spins up an isolated container.

* **Zero Conflicts:** A student in Period 1 named `jsmith` gets a container named `p1-jsmith`. A student in Period 3 named `jsmith` gets `p3-jsmith`. They never see or affect each other's files.  
* **Persistent Volumes:** Their home directories (`/home/student`) are mounted to folders on the host server. They can log off, and when they log back in the next day, their `.bashrc` modifications are exactly how they left them.  
* **Access Method:** Students can access their containers via **SSH** from their bare-metal workstations using a unique port assigned to them (e.g., `ssh student@classroom-server -p 2001`).

```
+----------------------------------------------------------------------------+
|                         CENTRAL CLASSROOM SERVER                           |
|                                                                            |
|  +-----------------------+ +-----------------------+                       |
|  |   PERIOD 1 BASKET     | |   PERIOD 2 BASKET     |                       |
|  |                       | |                       |                       |
|  | [Container: p1-jdoe]  | | [Container: p2-jdoe]  | ... 6 Periods Total   |
|  |  (SSH Port: 2001)     | |  (SSH Port: 2101)     |                       |
|  +-----------------------+ +-----------------------+                       |
|              |                         |                                   |
|              v                         v                                   |
|  +-----------------------------------------------------------------------+ |
|  | HOST CENTRAL GRADE STORAGE (Read-only to students, write-only by test)| |
|  |  - /var/grading/p1/jdoe.json                                          | |
|  |  - /var/grading/p2/jdoe.json                                          | |
|  +-----------------------------------------------------------------------+ |
+----------------------------------------------------------------------------+

```
</details>

## Repeated Practice on All Levels

The next few steps you will do in all 3 instances, so you can explore how they work before doing them on your [L1.1.3 \- Bare Metal, High Stakes](?tab=t.9eozfcfw4s5c) version.

### Step 1: Interrogating the True Host Space

1. Open your terminal natively on your Linux system partition.  
2. Print your current global execution tracks (`PATH`) to see where your operating system searches for executable software code routines.  
    <details>
    <summary> Step 1.2 code hint </summary>
        
    - You can show this list with the command: <code>echo $PATH</code>
    
    </details>

3. List all files inside your home user context—including hidden configuration assets.
    * Look for files starting with a dot, such as `.bashrc` or `.bash_profile`.
    <details>
    <summary> Step 1.3 code hint </summary>
        
    - Move into you home directory (if you're there, you don't move): <code>cd ~</code>
    - List everthing in the directory, in a table format: <code>ls -lah</code>

    </details>

### Step 2: Modifying Operating System Lifecycles

1. Open your configuration file (`.bashrc` or equivalent) using a command-line text editor.  
    <details>
    <summary> Step 2.1 code hint </summary>
        
    - To edit via terminal: <code>nano .bashrc</code> 
    > [!TIP] 
    > There are many CLI text editor beyond <code>nano</code> as well.
    
    </details>

2. Scroll to the very bottom of the file. Carefully inject an explicit environmental variable definition:

```shell
export ARCHITECT_CLEARANCE="LEVEL_4_HOST"
```

3. Save and close the text tool.  
4. Run an inspection command to check your new variable. Notice it outputs *nothing*\! Why? The current running shell process has not loaded the revised profile state yet.  
    <details>
    <summary> Step 2.4 code hint: more than one way to do this one</summary>

    There are many ways you can check to see if the variable is loaded. This is not an exhaustive list of commands...
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
```
6. Finally, run an inspection command again to see that the new variable has been loaded correctly.

## L1.1.1 Mission Overview

This part of the activity is nonconflicting, and unique to this level of the lab.

You are an infrastructure engineer tasked with adding a new security rule to an application's access control registry. You will intentionally create an alternate timeline (a branch), make a change that conflicts with the main timeline, and learn how to safely merge them back together.

### Step 1: Initialize Your Workspace

1. Open your terminal.  
2. Create a clean folder named `sandbox-vault` and move inside it.  
    <details>
    <summary> Step 1.2 code hint </summary>
        
    - <code>mkdir sandbox-vault</code> will make the directory inside the current working directory.
    - <code>cd sandbox-vault</code> moves you into that directory.
    
    </details>

3. Turn this `sandbox-vault` folder into a git tracked repository.
    <details>
    <summary> Step 1.3 code hint </summary>
        
    <code>git init</code> starts git tracking the repo. 
    *Note: Running `git init` creates a hidden `.git` folder that tracks every byte changed in this directory.*
    
    If you haven't yet setup git user details in this container, you are going to want to do that now:

        git config --global user.name "your_name_here"
        git config --global user.email "student@email.com"
        git config --global init.defaultBranch main

    </details>


### Step 2: Establish the Baseline Configuration

1. Create a file named `firewall_rules.config`.  
    <details>
    <summary> Step 2.1 code hint </summary>
        
    <code>touch firewall_rules.config</code> makes an empty file. 
 
    </details>

2. Open the file and add the following lines of code to represent your base network rules:
    ```
    RULE 01: ALLOW inbound port 80 (HTTP)
    RULE 02: ALLOW inbound port 443 (HTTPS)
    RULE 03: DENY all other inbound traffic
    ```
    <details>
    <summary> Step 2.2 code hint </summary>
        
    - <code>nano firewall_rules.config</code> will let you edit the file and add those lines. 

    OR

    - Run <code>echo "RULE 01: ALLOW inbound port 80 (HTTP)" >> firewall_rules.config</code> to append each line, one at a time.

    </details>

3. Save the file, stage it, and commit it to your master/main history timeline with a clear message.
    <details>
    <summary> Step 2.2 code hint </summary>

    - <code>git add firewall_rules.config</code> will add the changes to Git's staging area.
    - <code>git commit -m "feat: establish baseline production firewall rules"</code> makes a commit.
         
    </details>

### Step 3: Branch Out and Modify

1. Create and switch to a new branch named `feature-ssh`.  
    <details>
    <summary> Step 3.1 code hint </summary>

    - <code>git branch feature-ssh</code> will make a new branch in the project.
    - <code>git checkout feature-ssh</code> switches you to the named branch.

    OR

    - <code>git checkout -b feature-ssh</code> simultaneouly creates the branch and uses checkout to put you in it.

    </details>

2. Open `firewall_rules.config`. Change `RULE 03` to allow SSH connections, and shift the deny rule downward:

    ```
    RULE 01: ALLOW inbound port 80 (HTTP)
    RULE 02: ALLOW inbound port 443 (HTTPS)
    RULE 03: ALLOW inbound port 22 (SSH)
    RULE 04: DENY all other inbound traffic
    ```
    <details>
    <summary> Step 2.2 code hint </summary>
        
    <code>nano firewall_rules.config</code> is probably the 'cleanest' way to do this one... 

    Follow these sequential steps to reposition your line:
    1. Navigate your cursor to the targeted line using the arrow keys.
    2. Press <code>ENTER</code> to move the 'all other inboud traffic' rule downward and manually renumber it to 'RULE 04'.
    3. Use the arrow keys to go back up to the empty line, and add 'RULE 03' there.

    </details>

3. Stage and commit this change *on your feature branch*.
    <details>
    <summary> Step 3.3 code hint </summary>

    - <code>git add firewall_rules.config</code> will add the changes to Git's staging area.
    - <code>git commit -m "feat: allow inbound secure shell management port"</code> makes a commit.
         
    </details>

### Step 4: Induce a Timeline Collision (The Conflict)

1. Switch back to your primary `master` or `main` branch.  
    <details>
    <summary> Step 4.1 code hint </summary>

    - <code>git branch</code> will list all the local branches in the project.
    - <code>git checkout main</code> (or <code>master</code>) switches you to the default branch. Use the correct name for your repo.

    OR

    - <code>git checkout -</code> is a shortcut that takes you back to your last branch (probably <code>main</code>).

    </details>

2. Open `firewall_rules.config`. Notice that Rule 03 is still back to its original state\!  
    <details>
    <summary> Step 4.2 code hint </summary>

    Use <code>nano</code> or <code>cat</code> here:
    - <code>nano firewall_rules.config</code> opens the file in our favorite text-editor.
    - <code>cat firewall_rules.config</code> prints the file contents to the terminal for review (not edits).

    </details>

3. An emergency request comes in: clean up the rules by adding a comment. Change `RULE 03` to this:

    ```
    RULE 01: ALLOW inbound port 80 (HTTP)
    RULE 02: ALLOW inbound port 443 (HTTPS)
    RULE 03: DENY ALL UNAUTHORIZED TRAFFIC (EMERGENCY OVERRIDE)
    ```
    <details>
    <summary> Step 4.3 code hint </summary>
        
    <code>nano firewall_rules.config</code> is probably the 'cleanest' way to do this one... 

    Directly edit the correct line to have the correct content.

    </details>

4. Stage and commit this change directly to your main branch history.
    <details>
    <summary> Step 4.4 code hint </summary>

    - <code>git add firewall_rules.config</code> will add the changes to Git's staging area.
    - <code>git commit -m "fix: apply critical emergency block notice"</code> makes a commit.
         
    </details>

### Step 5: Merge and Resolve

1. You are on the main branch. Attempt to merge your `feature-ssh` changes into your current space.  
    <details>
    <summary> Step 5.1 code hint </summary>

    - <code>git branch</code> to confirm you are on the <code>main</code> (or <code>master</code>) branch.
    - <code>git merge feature-ssh</code> requests that you merge the 'feature-ssh' branch into your current branch.
         
    </details>

2. **Look at your terminal output.** The system will state that an automatic merge failed and you have a `CONFLICT`.  
3. Open `firewall_rules.config` in your editor. Locate the conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).  
    <details>
    <summary> Step 5.3 code hint </summary>
        
    <code>nano firewall_rules.config</code> is probably the 'cleanest' way to do this one... 

    At this step you are just *looking* for those merge-conflict markers.

    </details>

4. Manually clean up the file so that it keeps the security enhancements of both timelines:

    ```
    RULE 01: ALLOW inbound port 80 (HTTP)
    RULE 02: ALLOW inbound port 443 (HTTPS)
    RULE 03: ALLOW inbound port 22 (SSH)
    RULE 04: DENY ALL UNAUTHORIZED TRAFFIC (EMERGENCY OVERRIDE)
    ```
    <details>
    <summary> Step 5.4 & 5.5 code hint </summary>
        
    <code>nano firewall_rules.config</code> is probably the 'cleanest' way to do this one... 

    You've got to manually edit the file to make it look like what is above.
    
    </details>


5. After removing all system conflict markers, save the file, stage it, and commit to close the loop on this merge.  
    <details>
    <summary> Step 5.5 code hint </summary>

    - <code>git add firewall_rules.config</code> will add the changes to Git's staging area.
    - <code>git commit -m "merge: resolve firewall rule overlap between SSH provisioning and emergency block"</code> makes a commit.
         
    </details>

6. Verify your history graph using the visual terminal logger.
    <details>
    <summary> Step 5.6 code hint </summary>

    To view your timeline graph: <code>git log --graph --oneline</code>
         
    </details>


