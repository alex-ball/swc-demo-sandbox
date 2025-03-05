#!/usr/bin/env bash

LABEL=swc

use_lxd () {
	TOOL=LXD
	CONT=lxc
	CONT_SAVE="$CONT snapshot"
	make_lxc
}

use_incus () {
	TOOL=Incus
	CONT=incus
	CONT_SAVE="$CONT snapshot create"
	make_lxc
}

set_init () {
	case $CONT in
		lxc )
			CONT_INIT="lxc init ubuntu:lts $LABEL"
			;;
		incus )
			echo "Looking up available images..."
			IMAGE=$(incus image list -c L images:ubuntu | grep -E 'ubuntu/[0-9]{2}\.04/cloud' -o | tail -1)
			CONT_INIT="incus create images:$IMAGE $LABEL"
			;;
	esac
}

make_lxc () {
	# Ensure no existing instance
	STATUS="$($CONT list -c ns -f compact | grep $LABEL)"
	if [ $? -eq 0 ]
	then
		echo A container instance called $LABEL already exists. Replace?
		select yn in "Yes" "No"; do
			case $yn in
				Yes )
					if [[ $STATUS == *"RUNNING"* ]]
					then
						echo "Stopping $LABEL..."
						$CONT stop $LABEL
					fi
					echo "Removing $LABEL..."
					$CONT delete $LABEL
					break;;
				No )
					exit;;
			esac
		done
	fi

	# Create instance
	set_init
	echo "Creating Linux container for SWC teaching using $TOOL..."
	$CONT_INIT
	./mk-user-data | $CONT config set $LABEL user.user-data -

	# First run
	echo "Preparing file system..."
	$CONT start $LABEL
	$CONT exec $LABEL -- cloud-init status --wait

	# Snapshot
	echo "Creating $LABEL/clean snapshot..."
	$CONT_SAVE $LABEL clean

	# Handy alias
	USERCMD="exec --user 1000 --group 1000 --env HOME=/home/ubuntu @ARGS@ -- /bin/bash --login -c \$CMD"
	OLD_ALIAS=$($CONT alias list | grep " usercmd ")
	if [ $? -eq 0 ]
	then
		[[ $OLD_ALIAS =~ "| usercmd"[[:space:]]+"| "(.*)[[:space:]]+"|" ]]
		OLD_CMD=${BASH_REMATCH[1]}
		if [[ $OLD_CMD != $USERCMD ]]
		then
			echo "Alias 'usercmd' was set to « $OLD_CMD »."
			echo "Repurposing it for running commands as ubuntu user..."
			$CONT alias remove usercmd
			$CONT alias add usercmd "$USERCMD"
		fi
	else
		echo "Creating 'usercmd' alias for running commands as ubuntu user..."
		$CONT alias add usercmd "$USERCMD"
	fi

	echo "I have left the $LABEL instance running so you can try it out."
}

if command -v lxd 2>&1 >/dev/null
then
	use_lxd
else
	if command -v incus 2>&1 >/dev/null
	then
		use_incus
	else
		cat <<- 'EOS'
		Please install either LXD or Incus first:
		- snap install lxd
		- sudo apt install incus
		EOS
		exit 1
	fi
fi
echo "Done!"
