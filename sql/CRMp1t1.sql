-- Select all "Individual" contacts with "Ongoing" cases

-- Format: Contact display name, Employer organisation name, Number (count) of cases

-- Author: Patrick Parker, January 2017

-- Assumptions:
-- * Don't include "Urgent" cases
-- * Don't include past/future employment relationships, only current ones
-- * If multiple current employers exist, show them in a list format
-- * Ignore any data with is_deleted=1 or is_active=0
-- * Assume NULL is_deleted means Not Deleted (case schema allows NULL)

-- Discoveries:
-- * case schema should probably not allow NULL is_deleted
-- * it is possible for contact organization_name and employer_id to be
--   wrong. See https://github.com/sapientN3T/hello-world/issues/2


SELECT con.display_name as `Contact display name`,
  GROUP_CONCAT(
    DISTINCT emp.organization_name
    ORDER BY emp.sort_name
    SEPARATOR ', ') as `Employer organisation name(s)`,
  COUNT(DISTINCT `case`.id) as `Number (count) of cases`
FROM civicrm_option_group optgrp
INNER JOIN civicrm_option_value optval
  ON optval.option_group_id = optgrp.id
INNER JOIN civicrm_case `case`
  ON `case`.status_id = optval.`value`
INNER JOIN civicrm_case_contact ccon
  ON ccon.case_id = `case`.id
INNER JOIN civicrm_contact con
  ON ccon.contact_id = con.id
LEFT JOIN civicrm_relationship relat
  ON relat.contact_id_a = con.id
LEFT JOIN civicrm_relationship_type rtype
  ON relat.relationship_type_id = rtype.id
LEFT JOIN civicrm_contact emp
  ON relat.contact_id_b = emp.id
  AND relat.is_active=1
  AND (relat.start_date IS NULL OR relat.start_date <= DATE(NOW()))
  AND (relat.end_date IS NULL OR relat.end_date >= DATE(NOW()))
  AND rtype.name_b_a="Employer of"
  AND rtype.is_active=1
  AND emp.is_deleted=0
WHERE optgrp.`name`="case_status"
  AND optval.`name`="Open"
  AND (`case`.is_deleted IS NULL OR `case`.is_deleted=0)
  AND con.contact_type="Individual"
  AND con.is_deleted=0
GROUP BY con.id
ORDER BY con.sort_name;