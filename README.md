# obsidian_tools
Tool to:
1. Sync an [Obsidian](https://obsidian.md/) vault to a git remote
2. Convert links from wiki-link to markdown link formats
3. Convert math to GitHub/GitLab flavor markdown
4. Automate the above

The tools are split between two files:
- `convert_to_giltab.py`: a python script which converts math into GitHub/GitLab flavor markdown math notation and converts wikilinks into markdown links. When this code was first written, only GitLab supported [mermaid](https://mermaid.js.org/) diagrams, now GitHub does too. Feel free to use whichever service you want. 
- `auto_convertcommit.bat`: a `batch` script which automatically commits file changes and creates a temporary directory for `convert_to_giltab.py` to process changes
  - Welcome anyone who would like to create a `bash` version of this script. It should be much simpler than in `batch`.

## Software
The tools depend on two pieces of software:
- git
- Python (os, re, sys modules)

## Configuration
- Copy the files `convert_to_gitlab.py` and `auto_convertcommit.bat` into your Obsidian folder
- `convert_to_gitlab.py` assumes all attachments (e.g., images) are in a folder called `Attachments`. If your folder is named differently, edit line 11 in `convert_to_gitlab.py`.

### Git
- Create a git instance in your Obisidian folder: `git init`. The files as they appear in Obsidian are your `master` branch.
- Create a new branch called mdlinks: `git branch mdlinks`.
- Add a remote called `origin` linking to your GitHub or GitLab remote. 

Execute the batch script. You should now see two branches populated on your remote. You should be able to navigate `mdlinks` branch online including following links between files. 

You can either execute this script whenever you want to sync new changes, or, alternatively, see below for automating the process. 

### Automation
On Windows, `Task Scheduler` can be configured to automatically run this script periodically to keep you work backed up. The below images are an example configuration.  

<img width="400" alt="general" src="https://github.com/nwillems94/obsidian_tools/assets/42821240/bc255e85-0e82-4479-aeeb-b9c110981870">
<img width="400" alt="triggers" src="https://github.com/nwillems94/obsidian_tools/assets/42821240/0b54510d-fe48-44b3-a905-b5906f306765">
<img width="400" alt="actions" src="https://github.com/nwillems94/obsidian_tools/assets/42821240/75982e06-b7a7-4b3a-a5a7-1a013afd2f92">
<img width="400" alt="settings" src="https://github.com/nwillems94/obsidian_tools/assets/42821240/1f02e774-94b0-4ce0-9154-025b6bbc31f6">

Please submit a pull request if you can provide instructions on automating this on Linux or MacOS. 
