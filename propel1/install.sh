#!/usr/bin/env php
<?php

echo 'Please enter the name of the project: ';
$project_name = trim(fgets(STDIN));

echo 'Please enter the name of the database: ';
$db_name = trim(fgets(STDIN));

echo 'Please enter the database host: ("localhost")';
$db_host = trim(fgets(STDIN));
$db_host = $db_host? $db_host : 'localhost';

echo 'Please enter the database username: ("root")';
$db_username = trim(fgets(STDIN));
$db_username = $db_username ? $db_username : 'root';

echo 'Please enter the database password: ("")';
$db_password = trim(fgets(STDIN));
$db_password = $db_password ? $db_password : '';

$files = array();

$files['bootstrap.php'] = <<< BOOTSTRAP_PHP
<?php

require_once __DIR__ . DIRECTORY_SEPARATOR . 'constants.php';
require_once DIR_ROOT . '/db/propel/propel1/runtime/lib/Propel.php';
Propel::init(DIR_ROOT . '/db/build/conf/$project_name-conf.php');
set_include_path(DIR_ROOT . '/db/build/classes/' . PATH_SEPARATOR . get_include_path());
BOOTSTRAP_PHP;

$files['constants.php'] = <<< CONSTANTS_PHP
<?php

define('DIR_ROOT', __DIR__);

CONSTANTS_PHP;

$files['index.php'] = <<< INDEX_PHP
<?php

require_once './bootstrap.php';
INDEX_PHP;

$files['db/build.properties'] = <<< BUILD_PROPERTIES
propel.project = $project_name
propel.database = mysql
propel.database.url = mysql:dbname=$db_name
propel.database.user = $db_username
propel.database.password = $db_password
BUILD_PROPERTIES;

$files['db/runtime-conf.xml'] = <<< RUNTIME_CONF_XML
<?xml version="1.0" encoding="UTF-8"?>
<config>
	<propel>
		<datasources default="$project_name">
			<datasource id="$project_name">
				<adapter>mysql</adapter> <!-- sqlite, mysql, mssql, oracle, or pgsql -->
				<connection>
					<dsn>mysql:host=$db_host;dbname=$db_name</dsn>
					<user>$db_username</user>
					<password>$db_password</password>
				</connection>
			</datasource>
		</datasources>
	</propel>
</config>
RUNTIME_CONF_XML;

$EOL = PHP_EOL;
$files['regenerate.sh'] = <<< REGENERATE
#!/usr/bin/env bash $EOL

cd db $EOL
./propel/generator/bin/propel-gen . reverse $EOL
./propel/generator/bin/propel-gen $EOL
cd .. $EOL
REGENERATE;

$files['regenerate.bat'] = 'rem ' . str_replace('/', '\\', $files['regenerate.sh']);

mkdir('db');
foreach ($files as $filename => $contents) {
	file_put_contents($filename, $contents);
}
$current_perms = fileperms('regenerate.sh');
$new_perms = ($current_perms & 0777) | 0111;
chmod('regenerate.sh', $new_perms );

exec('git clone git://github.com/propelorm/Propel.git db' . DIRECTORY_SEPARATOR . 'propel');
chdir('db');
passthru(getcwd() . implode(DIRECTORY_SEPARATOR, array('', 'propel', 'generator', 'bin', 'propel-gen')) . ' . reverse');
passthru(getcwd() . implode(DIRECTORY_SEPARATOR, array('', 'propel', 'generator', 'bin', 'propel-gen')));

chdir(getcwd() . '/..');
