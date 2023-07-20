alias p := pull_rootfs
alias l := launch_qemu
alias c := config_linux
alias b := build_linux


linux_root := "/Users/lsw/Code/linux"
gen_compile_command := linux_root/"scripts/clang-tools/gen_compile_commands.py"
linux_output := "/Users/lsw/Code/linux_output"


docker_cmd :=  "docker run --platform linux/amd64 --privileged --rm -ti -v ~/Code:/Code -v /Volumes/xcompile:/Volumes/xcompile  -w /Code linux-builder"


pull_rootfs:
    #!/usr/bin/env zsh
    scp qdd:"~/Code/buildroot/output/images/rootfs.ext4" "./"

launch_qemu: 
	qemu-system-x86_64 -kernel {{linux_output}}/arch/x86_64/boot/bzImage -hda rootfs.ext4 -append "root=/dev/sda rw console=ttyS0" -nographic

config_linux:
    #!/usr/bin/env zsh
    {{docker_cmd}} "config"

build_linux:
    #!/usr/bin/env zsh
    {{docker_cmd}} "build"
    python3 {{gen_compile_command}} -d {{linux_output}} -o {{linux_root}}/compile_commands.json


header_linux:
    #!/usr/bin/env zsh
    {{docker_cmd}} "header"

copy_app:
    #!/usr/bin/env zsh
    {{docker_cmd}} "copy"

run_docker:
    @{{docker_cmd}} "bash" 

build_docker:
	@docker build --platform linux/amd64 -t linux-builder .
	@docker image prune
