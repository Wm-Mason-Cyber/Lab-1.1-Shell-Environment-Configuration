## 🌐 L1.1.2 Shared Classroom Container

**Risk Level:** Medium (Configuration Overwrite Risk)

**Objective:** Coordinate state changes across a network interface. You will experience how independent nodes colliding on shared infrastructure can disrupt production connectivity if not synchronized.  
   
**Environment:** Networked Shared Repository / Multi-User Target Node
<details>
<summary> Step 2 Architecture: Multi-User Shared Container </summary>

Instead of running 30 separate containers per class, you deploy **one container per period**. Students use their personal credentials to SSH into the same shared environment.

##### Security and Isolation Boundary

**Home Directory Containment:** Every student user account is provisioned with traditional POSIX isolation permissions (`chmod 700`), meaning `jsmith` cannot peek into or modify `/home/bwilliams/`.

**Shared Space vs. Private Shells:** While students share CPU, memory, and common directories like `/opt/`, their shell configurations (`~/.bashrc`, `~/.profile`) are bound to their private home profiles.

* **The "Shared Machine" Reality:** Students can run commands like `who` or `ps aux` and see their classmates working in real-time, simulating a true enterprise server.

</details>

## Repeated Practice on All Levels

The next few steps you will do in all 3 instances, so you can explore how they work before doing them on your [L1.1.3 \- Bare Metal, High Stakes](?tab=t.9eozfcfw4s5c) version.

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
```
6. Finally, run an inspection command again to see that the new variable has been loaded correctly.
    - See the command hint above from 2.4 for guidance.

### 

## L1.1.2 Mission Overview

You are working on a federated central server infrastructure. You and a classmate will pull configurations down from a shared server engine, simultaneously submit conflicting network rules, and coordinate remote resolution pipelines over the network interface.

### Step 1: Authenticate and Clone the Central Vault

This will give you a local copy of the server’s files. Since this ‘network matrix’ is tracked by git, you can push/pull changes from your version to the shared copy.

1. Clone the central configuration tree down to your local staging directory.  

> [!IMPORANT]  
> This Step 1.1 works best when everyone in the class does it at *nearly* the same time. It makes it more of a 

```shell
git clone /srv/class/network_matrix.git ~/network_matrix
cd ~/network_matrix
```

### Step 2: Establish a Unique Identity

Your user on this shared container is new, so you have to set up your `git` credentials.  
 

1. Run commands to tell the configuration management tracker who you are.

```shell
git config user.name "Your Name"
git config user.email "yourstudent@email.com"
```

### Step 3: Claim an Allocation Slot

Because multiple nodes are connecting to this single repository, you must register your specific workspace handle.

1. Open the shared file named `network_matrix.json` with a command line text editor (such as `nano`).  
    <details>
    <summary> Step 3.1 Command Hint</summary>
    <code>nano network_matrix.json</code> will open the correct file in the nano text editor, provided you are in the expected location.
    </details>

2. Locate an unassigned row or object ID slot matching your designated lab seating coordinate. 
    <details>
    <summary> Step 3.2 Command Hint</summary>
    Pick any row in the repetitive part of the array in the JSON file. 
    Git has a 3 line minimum for size to check for conflicts on any change (even single character changes).
    If you choose a row 'too far' from anyone else, or are first, you will not likely trigger a merge conflict. 
    </details>
    
3. Inject your workstation parameters into that block.   
    1. Change the allocation state from `"Status": "AVAILABLE"` to `"Status": "PROVISIONED_BY_WORKSTATION_X"`. (Put in your workstation number or name instead of `WORKSTATION_X`.) Update other items in the row accordingly.  
    2. Change `"provisioned_by": null` to `"provisioned_by":` any version of your name (real\_name, username, etc).  
    3. Change  `"provisioned_at": null` to `"provisioned_at":` the current time (at least down to the minute).  
    <details>
    <summary> Step 3.3 Command Hint</summary>
    
    An example:
    
    <code> { "seat": "A3", "status": "AVAILABLE", "provisioned_by": null, "provisioned_at": null },</code>
    
    is changed to: 
    
    <code> { "seat": "A3", "status": "PROVISIONED_BY_WORKSTATION_A3", "provisioned_by": Spongebob, "provisioned_at": 11:59:03AM },</code>
    </details>
    
4. Stage and commit your changes locally.
   <details>
   <summary>Step 3.4 Command Hint</summary>

	You will stage and commit as usual for any git-tracked repo:
    - <code>git add network_matrix.json</code> to stage the commit.
    - <code>git commit -m "allocated a workstation to myself"</code> to make a commit"
    </details>

### Step 4: Race Condition Deployment (The Push)

Merge conflicts are common issues when multiple people can directly connect to a git repo (this is specifically what GitHub-style Forks & Pull Requests solve). The first person to make a change will be not raise a conflict, but any subsequent overlapping changes will need to be manually resolved. 

1. Attempt to transmit your local history adjustments directly up to the central network repository tracker.

To attempt tracking transmission:

```shell
git push origin main
```

2. **If a classmate pushed their changes first**, your terminal will throw a critical rejection warning: `[rejected - non-fast-forward]`. This means the central state has advanced beyond your local knowledge footprint.

If rejected, you must fetch the remote network changes and combine them locally before trying again:

```shell
git pull origin main
```

### Step 5: Network Conflict Coordination

0. \[Quickhands: you did not get a conflict above\] *If you were simply able to `git push`, then partner up with someone to see the rest of the process.*   
1. If your `git pull` triggers a conflict flag inside `network_matrix.json`, look across the room\! Find the classmate whose changes overlapped with your allocation space or array markers.  
2. Verbally ~~or via shared logs~~, negotiate who claims which array structure.  
3. Clean the collision markers (`<<<<<<<`, `=======`, `>>>>>>>`) out of the JSON file, ensuring the formatting remains valid JSON structure.  
4. Stage, commit, and push your resolved configuration up to the central server. Verify the remote updates appear online or on your instructor's tracking monitor.
   <details>
   <summary>Step 5.4 Command Hint</summary>

	You will stage and commit as usual for any git-tracked repo:
    - <code>git add network_matrix.json</code> to stage the commit.
    - <code>git commit -m "resolved merge conflict with origin/main"</code> to make a commit"
    </details>


## Self Evaluation of Your Work

Just run `check-lab` from your SSH session, no arguments needed. `$USER` resolves to your username automatically.  
This should output the score you will receive on this section of the lab.

> [!TIP]  
> There is a script (you can see) at `/usr/local/bin/check-lab` that describes the evaluation rules for how this is scored.   