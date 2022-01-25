# Setting up fresh container for SWC

Initial setup:

```bash
./setup-swc-lxc.sh
```

# Using the image for teaching

To reset any previous changes:

```bash
lxc restore swc clean
```

To prepare the image for the Shell lesson:

```bash
lxc exec --user 1000 swc -- unzip /home/ubuntu/Downloads/shell-lesson-data.zip -d ~/Desktop/
```

To launch the demo terminal:

```bash
lxc exec --user 1000 swc -- /home/ubuntu/Applications/demo-terminal.sh
```

To launch a second demo terminal:

```bash
lxc exec --user 1000 swc -- /bin/bash
SESSION=swc2 /home/ubuntu/Applications/demo-terminal.sh
```

# Tear down

If you want to remove/replace the container:

```bash
lxc stop swc
lxc delete swc
```
