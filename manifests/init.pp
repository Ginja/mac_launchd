# Parameters:
# ensure      - Value must be present or absent. Used for placing files.
# label       - Label key inside the launchd plist. Needed for loading and unloading.
# type        - Value must be 'LaunchAgents' or 'LaunchDaemons'. Used for determing where to place launchd job.
# launchdf    - Value must be the name of the launchd plist. File needs to be stored in this module's files/$fdir directory.
# load        - Value must be true or false (no quotes). Used for determining whether or not to load or unload a launchd job.
# fdir        - Value must be the same as one of the folders in the files directory of this module. Needed for organizational purposes.
# script      - Default value is ''. Any other value must be a script located in the $fdir directory. Specify only if your launchd job calls a script
# script_path - Path where you want to store your script on the client side. Make sure your launchd job plist calls the script from this location.
# owner       - Default value is 'root'. Any other value must be a valid user. Used for setting the script's owner.
# group       - Default value is 'wheel'. Any other value must be a valid group. Used for setting the script's group.
# mode        - Default value is '0555'.
#
# Example:
#  Loading a job with a script:
#      mac_launchd { 'somejob-load':
#        ensure      => 'present',
#        label       => 'ca.someplace.somedept.somejob',
#        type        => 'LaunchAgents',
#        launchdf    => 'ca.someplace.somedept.somejob.plist',
#        load        => true,
#        script      => 'somejob.scpt',
#        script_path => '/Library/Scripts/launchd_scripts',
#        fdir        => 'SomeDept',
#      }
#  Unloading a job with a script:
#      mac_launchd { 'somejob-unload':
#        ensure      => 'absent',
#        label       => 'ca.someplace.somedept.somejob',
#        type        => 'LaunchAgents',
#        launchdf    => 'ca.someplace.somedept.somejob.plist',
#        load        => false,
#        script      => 'somejob.scpt',
#        script_path => '/Library/Scripts/launchd_scripts',
#        fdir        => 'SomeDept',
#      }
#
# Caveats:
#  For now, unloading a job that has a script does not remove that script.
#  If you are unloading a job with a script ensure you still specify a script_path, otherwise you'll have errors in your puppet runs.

define mac_launchd ( $ensure,
		     $label,
		     $type,
		     $launchdf,
		     $load,
		     $fdir,
		     $script      = '',
		     $script_path = '',
		     $owner       = 'root',
		     $group       = 'wheel',
		     $mode        = '0555',
) {
  # Fail early, fail hard
  if ($ensure != present) and ($ensure != absent) {
    fail("The ensure paramaeter needs to be set to present or absent - ${ensure} -")
  }
  if $launchdf == '' {
    fail("No launchd plist file specified!")
  }
  if ($load != true) and ($load != false) {
    fail("The load parameter needs to be set to true or false (no quotes) - ${load} -")
  }

  $fullpath = $type ? {
    'LaunchAgents' => "/Library/LaunchAgents/${launchdf}",
    'LaunchDaemons' => "/Library/LaunchDaemons/${launchdf}",
  }

  case $type {
    'LaunchAgents','LaunchDaemons': {
      file { $launchdf:
        ensure => $ensure,
        path    => $fullpath,
        source  => "puppet:///modules/mac_launchd/${fdir}/${launchdf}",
        owner   => 'root',
        group   => 'wheel',
        mode    => 0644,
      }

      if $script {
        exec { "create-${title}-${script_path}":
          command => "/bin/mkdir -p ${script_path}",
	        creates => "${script_path}",
        }

        file { "${script_path}/${script}":
          ensure  => $ensure,
          owner   => $owner,
          group   => $group,
          mode    => $mode,
          source  => "puppet:///modules/mac_launchd/${fdir}/${script}",
	        require => Exec["create-${title}-${script_path}"],
        }
      }
      else {
        notify{ "${title}-script":
          message => "No script was specified for resource ${title}, but I assume you know that",
        }
      }
      if $load == true {
        exec { "load-${label}":
          command => "/bin/launchctl load -w ${fullpath}",
          unless  => "/bin/launchctl list | grep ${label}",
          require => File[$launchdf, "${script_path}/${script}"],
        }
      }
      elsif $load == false {
        exec { "unload-${label}":
          command => "/bin/launchctl unload -w ${fullpath}",
          onlyif  => "/bin/launchctl list | grep ${label}",
          before  => File[$launchdf, "${script_path}/${script}"],
        }
      }
    }
    default: {
      fail("The type parameter needs to be set to 'LaunchAgents' or 'LaunchDaemons' - ${type} -")
    }
  }
}

