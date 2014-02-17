class dodjango::base (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $group = 'www-data',
  
  $path = '/var/www/html',
  $project = 'djangostarter',

  # don't monitor by default, because site content will change for most people
  $monitor = false,

  # end of class arguments
  # ----------------------
  # begin class

) {

  # monitor if turned on
  if ($monitor) {
    class { 'dodjango::monitor' : }
  }

  # create a django project
  exec { 'django-create-project' :
    path    => '/usr/bin:/bin:',
    command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && cd ${path} && django-admin.py startproject ${project}\"",
    user    => $user,
    group   => $group,
    onlyif  => "test ! -e ${path}/${project}",
  }->

  # create symlink from our home folder
  file { "/home/${user}/${project}":
    ensure => 'link',
    target => "${path}/${project}",
  }->

  # use installapp macro to install repo, hosts and vhosts
  dorepos::installapp { 'appconfig-django' :
    user => $user,
    group => $group,
    repo_source => 'git://github.com/devopera/appconfig-django.git',
    # important: mod_wsgi crashes and leaves dead processes that stall all future (service httpd restart) calls
    # if we try and do a (service httpd graceful) as part of the installapp django
    refresh_apache => false,
  }

}
