mac_launchd
===========

Puppet module for loading and unloading launchd jobs on OS X.

Module parameters:

*	ensure
  *	Value must be present or absent. Used for placing files.
*	label
  *	Label key inside the launchd plist. Needed for loading and unloading.
* type
  * Value must be 'LaunchAgents' or 'LaunchDaemons'. Used for determing where to place launchd job.
*	launchdf
  *	Value must be the name of the launchd plist. File needs to be stored in this module's files/$fdir directory.
* load
  * Value must be true or false (no quotes). Used for determining whether or not to load or unload a launchd job.
* fdir
  * Value must be the same as one of the folders in the files directory of this module. Needed for organizational purposes.
*	script
  *	Default value is ''. Any other value must be a script located in the $fdir directory. Specify only if your launchd job calls a script
*	script_path
  *	Path where you want to store your script on the client side. Make sure your launchd job plist calls the script from this location.
*	owner
  *	Default value is 'root'. Any other value must be a valid user. Used for setting the script's owner.
*	group
  *	Default value is 'wheel'. Any other value must be a valid group. Used for setting the script's group.
*	mode
  *	Default value is '0555'.

Example launchd plist, which calls an AppleScript:

 ```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>ca.someplace.somedept.somejob</string>
	<key>ProgramArguments</key>
	<array>
		<string>/usr/bin/osascript</string>
		<string>-e</string>
		<string>run script (POSIX file "/some/path/launchd_scripts/my_special_script.scpt")</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
 ```
 
Example Puppet resource which places, and loads the above plist:
 
 ```puppet
mac_launchd { 'somejob-load':
  ensure      => 'present',
  label       => 'ca.someplace.somedept.somejob',
  type        => 'LaunchAgents',
  launchdf    => 'ca.someplace.somedept.somejob.plist',
  load        => true,
  script      => 'my_special_script.scpt',
  script_path => '/Library/Scripts/launchd_scripts',
  fdir        => 'SomeDept',
}
 ```

In this example, the files directory of this module would need to contain the launchd plist, and the AppleScript.

Example:

* mac_launchd/
  * files/SomeDept/ca.someplace.somedept.somejob.plist
  * files/SomeDept/my_special_script.scpt
  * lib/
  * manifest/init.pp
  * spec/
  * templates/
  * tests/

Example Puppet resource that removes, and unloads the above plist:

 ```puppet
mac_launchd { 'somejob-load':
  ensure      => 'absent',
  label       => 'ca.someplace.somedept.somejob',
  type        => 'LaunchAgents',
  launchdf    => 'ca.someplace.somedept.somejob.plist',
  load        => false,
  script      => 'my_special_script.scpt',
  script_path => '/Library/Scripts/launchd_scripts',
  fdir        => 'SomeDept',
}
 ```

Caveats:

* For now, unloading a job that has a script does not remove that script.
* If you are unloading a job with a script ensure you still specify a script_path, otherwise you'll have errors in your puppet runs.
