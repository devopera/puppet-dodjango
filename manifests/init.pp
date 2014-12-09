class dodjango (

  # class arguments
  # ---------------
  # setup defaults

  $user = 'web',
  $proxy_pip = '',
  $release = 'official',
  $release_branch = undef,

  $install_basics = true,
  $install_pil = true,
  $install_mptt = true,
  $install_mptt_using_pip = true,
  $install_memcached = true,

  # end of class arguments
  # ----------------------
  # begin class

) {

  if ($release == 'official') {
    # append explicit version number if set
    if ($release_branch != undef) {
      $release_version = "==${release_branch}"
    } else {
      $release_version = ''
    }
    # install official release using pip
    exec { 'install-django' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} Django${release_version}\"",
    }
  } elsif ($release == 'beta') {
    # clone the master branch from the django git repo
    dorepos::getrepo { "django-trunk" :
      source => 'git://github.com/django/django.git',
      branch => "stable/${release_branch}",
      user => $user,
      # installing in user's home directory, so user:group = $user
      group => $user,
      provider => 'git',
      path => "/home/${user}",
    }->
    
    # use pip to make Django's code importable and setup django-admin.py utility
    exec { 'install-django' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install -e /home/${user}/django-trunk/\"",
    }
  }

  # install numpy, mysql connector and south
  if ($install_basics) {
    exec { 'install-numpy' :
      path    => '/usr/bin:/bin:',
      timeout => 600,
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} numpy\"",
    }->
  
    exec { 'install-mysql-python' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} MySQL-python\"",
    }->
  
    exec { 'install-south' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} South\"",
    }
  }

  # install Python Imaging Library
  if ($install_pil) {
    exec { 'install-pil' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} --no-index -f http://dist.plone.org/thirdparty/ -U PIL\"",
    }
  }

  # install Memcached
  
  if ($install_memcached) {
    exec { 'install-memcached' :
      path    => '/usr/bin:/bin:',
      command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet python-memcached\"",
    }
  }

  # install MPTT (Modified Preorder Tree Traversal) 
  if ($install_mptt) {
    if ($install_mptt_using_pip) {
      # install MPTT using pip
      exec { 'install-mptt-pip' :
        path    => '/usr/bin:/bin:',
        command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && pip install --quiet ${proxy_pip} django-mptt\"",
      }
    } else {
      # install MPTT from source, if not already installed
      exec { 'install-mptt-source' :
        path    => '/usr/bin:/bin:',
        command => "bash -c \"source /usr/local/pythonenv/galaxy/bin/activate && wget https://pypi.python.org/packages/source/d/django-mptt/django-mptt-0.5.5.tar.gz -O /tmp/django-mptt-latest.tar.gz && cd /tmp && tar -xf /tmp/django-mptt-latest.tar.gz && cd /tmp/django-mptt-0.5.5 && python setup.py install\"",
        onlyif  => "test ! -d /usr/local/pythonenv/galaxy/lib/python2.7/site-packages/mptt",
      }->
      # clean up as root because wget creates permissioned file
      exec { 'install-mptt-cleanup' :
        path    => '/usr/bin:/bin:',
        command => 'rm -rf /tmp/django-mptt-*',
      }
    }
  }


}
