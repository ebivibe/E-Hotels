DROP VIEW IF EXISTS employeeroles;
CREATE VIEW employeeroles AS
  SELECT r.role_id, er.employee_ssn as ssn, r.name, r.description
   FROM Role r
     INNER JOIN EmployeeRole er ON r.role_id = er.role_id ;
