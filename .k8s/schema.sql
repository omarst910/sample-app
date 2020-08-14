CREATE DATABASE IF NOT EXISTS test;
USE test;
DROP TABLE IF EXISTS `employee`;
CREATE TABLE `employee` (
  `id` int(6) unsigned NOT NULL AUTO_INCREMENT,
  `first_name` varchar(30) NOT NULL,
  `department` varchar(30) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;


INSERT INTO employee (first_name, department)
VALUES ('Tom', 'Accounting');

INSERT INTO employee (first_name, department)
VALUES ('Adam', 'Engineering');

INSERT INTO employee (first_name, department)
VALUES ('Sam', 'HR');

INSERT INTO employee (first_name, department)
VALUES ('Rob', 'HR');

INSERT INTO employee (first_name, department)
VALUES ('Sarah', 'Accounting');