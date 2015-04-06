-- jobs
DROP TABLE IF EXISTS `jobs`;
CREATE TABLE `jobs` (
  `id` integer PRIMARY KEY AUTO_INCREMENT NOT NULL, 
  `job_id` varchar(255) NOT NULL UNIQUE, 
  `job_def_id` varchar(255), 
  `update_id` integer UNSIGNED NOT NULL, 
  `state` tinyint NOT NULL, 
  `content` text, 
  `start_after` datetime, 
  `node` varchar(255), 
  `host` varchar(255), 
  `priority` integer
); 
CREATE  INDEX `index_jobs_on_job_id` ON `jobs` (`job_id`);
CREATE  INDEX `index_jobs_on_update_id` ON `jobs` (`update_id`);
CREATE  INDEX `index_jobs_on_state` ON `jobs` (`state`);
INSERT INTO jobs (job_id, state, update_id) VALUES('INITIATOR',0,0);

-- producers
DROP TABLE IF EXISTS `producers`;
CREATE TABLE `producers` (
  `job_id` integer NOT NULL, 
  `product` varchar(255) NOT NULL,
  PRIMARY KEY (job_id, product)
);
CREATE  INDEX `index_producers_on_job_id` ON `producers` (`job_id`);
CREATE  INDEX `index_producers_on_product` ON `producers` (`product`);

-- consumers
DROP TABLE IF EXISTS `consumers`; 
CREATE TABLE `consumers` (
  `product` varchar(255) NOT NULL, 
  `job_id` integer NOT NULL, 
  PRIMARY KEY (job_id, product)
); 
CREATE  INDEX `index_consumers_on_job_id` ON `consumers` (`job_id`);
CREATE  INDEX `index_consumers_on_product` ON `consumers` (`product`);

-- flows
DROP TABLE IF EXISTS `flows`; 
CREATE TABLE `flows` (
  `producer_id` integer NOT NULL, 
  `consumer_id` integer NOT NULL,
  PRIMARY KEY (producer_id, consumer_id)
); 
CREATE  INDEX `index_flows_on_producer_id` ON `flows` (`producer_id`);
CREATE  INDEX `index_flows_on_consumer_id` ON `flows` (`consumer_id`);

-- job_profiles
DROP TABLE IF EXISTS `job_profiles`; 
CREATE TABLE `job_profiles` (
  `id` integer PRIMARY KEY AUTO_INCREMENT NOT NULL, 
  `job_id` varchar(255) NOT NULL, 
  `node` varchar(255), 
  `host` varchar(255), 
  `thread` varchar(255), 
  `begin_at` datetime, 
  `end_at` datetime, 
  `description` text, 
  `state` tinyint
); 
CREATE  INDEX `index_job_profiles_on_job_id` ON `job_profiles` (`job_id`);
CREATE  INDEX `index_job_profiles_on_state` ON `job_profiles` (`state`);

