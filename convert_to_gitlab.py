# %%
import os, re, sys

master_path = os.path.dirname(os.path.realpath(__file__)) +\
                "\\" if os.name=="nt" else "/"
convert_file = str(sys.argv[1])

# %% get all (relevant) file paths for linking
paths = [os.path.join(r, note) for r, _, f in os.walk(master_path) for note in f 
        if r.find("\\." if os.name=="nt" else "/.")==-1 and note.endswith('.md')]
paths.extend([os.path.join(r, img) for r, _, f in os.walk(master_path + 'Attachments') for img in f])

# %% exit if file does not exist
if os.path.basename(convert_file) not in [os.path.basename(p) for p in paths]:
    sys.exit()

# exit if not a markdown file
if not convert_file.endswith('.md'):
    sys.exit()

print(convert_file)

# %% convert to relative paths
paths = [os.path.relpath(p, start=os.path.dirname(master_path + convert_file)) for p in paths]

# %%
# read in the master wiki-linked file as input
with open(master_path+convert_file, 'rt', encoding='UTF-8') as fin:
    # read a list of lines into data
    input_text = fin.readlines()

# output to the mdlinks branch
with open(convert_file, 'wt', encoding='UTF-8') as fout:
    for line in input_text:
        ## Convert math to gitlab flavor markdown
        # math on it's own line
        math = re.findall('\$\$(.*?)\$\$', line)
        for m in math:
            # indent for following lines
            indent = re.findall('^( *)\$\$', line)
            indent = '\n'+str(indent[0]) if len(indent)>0 else '\n'
            line = line.replace('$$'+m+'$$', '```math'+ indent+m+ indent+'```')
        
        # spaces in inline math must be escaped twice
        math = [m for m in re.findall('\$(.*?)\$', line)]
        for m in math:
            # obsidian does not allow inline math to end with a space
            if(m[-1]!=' '):
                line = line.replace('$'+m+'$', '$'+re.sub(r'\\(,|>|:|;)', r'\\\\\1', m)+'$')


        ## Convert wikilinks to markdown links
        # extract wikilinks
        links = [m for m in re.findall('\[\[(.*?)\]\]', line)]
        if len(links)==0:
            fout.write(line)
            continue

        # extract alt text
        link_text = [l.split('#')[0] if l.find('|')==-1 else l.split('|')[1] for l in links]
        link_heading = ['' if l.find('#')==-1 else '#'+l.split('#')[1] for l in links]

        link_path=[]
        for l, h in zip(links, link_heading):
            link_path.append([(path + h).replace(' ','%20') for path in paths
                                if path.endswith(l.split('|')[0].split('#')[0] + '.md')])

        for l, lt, lp in zip(links, link_text, link_path):
            # if note doesn't exist yet, leave link alone
            if len(lp)==0:
                continue
            # only convert if file is unique
            elif len(lp)==1:
                line = line.replace('[['+l+']]', '['+lt+']' + '('+lp[0].replace('\\','/')+')')

        fout.write(line)