-- ***********************
-- Name: Jay Pravinkumar Chaudhari
-- ID: 147268205
-- Date: 29th of July 2022
-- Purpose: FINAL PROJECT DBS311
-- ***********************

--Question 1: Write a query which lists the employee (from EMPLOYEE table) with the highest total
--compensation (includes SALARY, BONUS and COMMISSION) by department and job type.
SELECT
    emp.empno, emp.job, emp.workdept
    , NVL(emp.salary, 0) + NVL(emp.bonus, 0) + NVL(emp.comm, 0) AS "Total Compensation"
FROM employee emp
WHERE NVL(emp.salary, 0) + NVL(emp.bonus, 0) + NVL(emp.comm, 0) IN
                (SELECT
                    MAX(NVL(emp.salary, 0) + NVL(emp.bonus, 0) + NVL(emp.comm, 0)) AS "Total Compensation"
                FROM employee emp
                GROUP BY emp.workdept)
ORDER BY emp.workdept, emp.job;

--Question 2: Write a query which shows the complete list of last names from both the EMPLOYEE table
--and STAFF table. Make sure your query is case insensitive (ie SMITH = Smith = smith).

SELECT DISTINCT list_of_names.*
FROM 
    (SELECT initcap(lower(lastname)) AS lastname
    FROM employee
    UNION ALL
    SELECT initcap(lower(name)) AS lastname FROM staff) list_of_names
ORDER BY list_of_names.lastname;

--Question 3: Write a query which shows where we have two employees assigned to the same employee
--number, when looking across both EMPLOYEE table and STAFF table.
SELECT emp.empno, emp.lastname AS "EMPLOYEE LASTNAME", st.name AS "STAFF LASTNAME"
FROM employee emp inner join staff st on CAST(emp.empno AS NUMBER) = st.id 
ORDER BY emp.empno, emp.lastname;

--Question 4: Write a query which lists all employees across both the STAFF and EMPLOYEE table, which
--have an �oo� OR a �z� in their last name.
SELECT distinct list_of_employees.* FROM 
    (SELECT lastname AS lname 
    FROM employee WHERE LOWER(lastname) LIKE '%oo%' OR LOWER(lastname) LIKE '%z%'
    UNION ALL
    SELECT name AS lname 
    FROM staff WHERE LOWER(name) LIKE '%oo%' OR LOWER(name) LIKE '%z%' ) list_of_employees 
ORDER BY list_of_employees.lname;

--Question 5: Write a query which looks at the EMPLOYEE table and, for each department, compares the
--manager�s total compensation (SALARY, BONUS and COMMISSION) to the top paid
--employee�s total compensation and displays output if the top paid employee in that
--department makes within $10,000 in total compensation as compared to their manager
SELECT a.workdept, a.manager_compensation, b.max_employee FROM
(SELECT empno,workdept, SUM(salary+bonus+comm)AS manager_compensation FROM employee WHERE job='MANAGER' GROUP BY empno, workdept) a inner join 
(SELECT workdept,max(employee_compensation)AS max_employee FROM 
(SELECT empno,workdept, SUM(salary+bonus+comm) AS employee_compensation FROM employee WHERE job !='MANAGER' GROUP BY empno,workdept ORDER BY workdept,empno desc) GROUP BY workdept) b on a.workdept = b.workdept 
WHERE (a.manager_compensation - b.max_employee) <10000;

--Question 6: Write a query which looks across both the EMPLOYEE and STAFF table and returns the total
--�variable pay� (COMMISSION + BONUS) for each employee.
SELECT
    INITCAP(emp.lastname) lastname,(NVL(emp.comm, 0) + NVL(emp.bonus,0)) AS variable_pay
FROM employee emp

UNION

    SELECT 
        INITCAP(name), NVL(comm,0) AS variable_pay
    FROM staff

ORDER BY lastname;


--Question 7: Write a stored procedure for the EMPLOYEE table which takes, as input, an employee number
--and a rating of either 1, 2 or 3.
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE update_salary(empId IN NUMBER, empRating IN NUMBER)

AS
    OUT_OF_RANGE EXCEPTION;
    empSalary employee.salary%TYPE;
    empBonus employee.bonus%TYPE;
    empComm employee.comm%TYPE;
    newSalary employee.salary%TYPE;
    newBonus employee.bonus%TYPE;
    newComm employee.comm%TYPE;
    
BEGIN     
    SELECT 
        salary, bonus, comm
    INTO empSalary, empBonus, empComm
    FROM employee
    WHERE CAST(empno AS NUMBER) = empId;

    IF empRating NOT IN (1, 2, 3) THEN
        RAISE OUT_OF_RANGE;
    
    ELSE   
        IF empRating = 1 THEN
            newSalary:= empSalary + 10000;
            newBonus:= empBonus + 300;
            newComm:= empComm * 1.05;

        ELSIF empRating = 2 THEN 
            newSalary:= empSalary + 5000;
            newBonus:= empBonus + 200;
            newComm:= empComm * 1.02;

        ELSE 
            newSalary:= empSalary + 2000;
            newBonus:= empBonus;
            newComm:= empComm;
                
        END IF;
        
        DBMS_OUTPUT.PUT_LINE ('EMP ID: ' || empId);
        DBMS_OUTPUT.PUT_LINE ('PREV SALARY: ' || empSalary);
        DBMS_OUTPUT.PUT_LINE ('PREV BONUS: ' || empBonus);   
        DBMS_OUTPUT.PUT_LINE ('PREV COMM: ' || empComm);     
        DBMS_OUTPUT.PUT_LINE ('NEW SALARY: ' || newSalary);
        DBMS_OUTPUT.PUT_LINE ('NEW BONUS: ' || newBonus);    
        DBMS_OUTPUT.PUT_LINE ('NEW COMM: ' || newComm);
    
    END IF;
    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE ('ERROR: INVALID Employee ID');
        WHEN OUT_OF_RANGE THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: INVALID RATING');

END;
/



--Question 8: Write a stored procedure for the EMPLOYEE table which takes employee number and
--education level upgrade as input - and - increases the education level of the employee based
--on the input.
SET SERVEROUTPUT ON;

CREATE OR REPLACE PROCEDURE update_education(empId IN NUMBER, educUpgrade IN CHAR)

AS
       REDUCE_EDUCATION EXCEPTION;
       empEdLevel employee.edlevel%TYPE;
       targetNewEdLevel employee.edlevel%TYPE;
       newEdLevel employee.edlevel%TYPE;
 
BEGIN     
    SELECT edlevel
    INTO empEdLevel
    FROM employee
    WHERE CAST(empno AS NUMBER) = empId;
    
    CASE UPPER(educUpgrade)
            WHEN 'H' THEN targetNewEdLevel:= 16;
            WHEN 'C' THEN targetNewEdLevel:= 19;
            WHEN 'U' THEN targetNewEdLevel:= 20;
            WHEN 'M' THEN targetNewEdLevel:= 23;
            WHEN 'P' THEN targetNewEdLevel:= 25;
            ELSE DBMS_OUTPUT.PUT_LINE('ERROR: INVALID ED LEVEL GIVEN');
        END CASE;
    
    IF targetNewEdLevel < empEdLevel THEN
        RAISE REDUCE_EDUCATION;
        
    ELSE
        newEdLevel:= targetNewEdLevel;
    END IF;
    
    DBMS_OUTPUT.PUT_LINE ('EMPLOYEE ID: ' || empId);
    DBMS_OUTPUT.PUT_LINE ('PREV EDUCATION LEVEL: ' || empEdLevel);
    DBMS_OUTPUT.PUT_LINE ('NEW EDUCATION LEVEL: ' || newEdLevel);
          
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE ('ERROR: EMPLOYEE ID');
        WHEN REDUCE_EDUCATION THEN
            DBMS_OUTPUT.PUT_LINE('ERROR: CANNOT REDUCE EXISTING EDUCATION LEVEL');


END;  
/

--Question 9: Write a function called PHONE which takes an employee number as input and displays a full
--phone number for that employee, using the PHONENO value as part of the function.
SET SERVEROUTPUT ON;

ALTER TABLE employee MODIFY phoneno VARCHAR2(14);

CREATE OR REPLACE FUNCTION phone(empId IN NUMBER) 
RETURN VARCHAR2
IS 
fullPhoneNo VARCHAR2(14);

BEGIN 

    SELECT 
        CONCAT(CONCAT('(416) 123','-'), phoneno)
    INTO fullPhoneNo
    FROM employee 
    WHERE CAST(empno AS NUMBER) = empId;
    
    DBMS_OUTPUT.PUT_LINE ('PHONE NUMBER: ' || fullPhoneNo);
    RETURN fullPhoneNo;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ERROR: INVALID EMPLOYEE ID');
 END;
 /



--Question 10: Write a stored procedure which calls your PHONE function. 

SET SERVEROUTPUT ON;
ALTER TABLE employee ADD phonenum VARCHAR(14);

CREATE OR REPLACE PROCEDURE updatephone

AS
    empid employee.empno%TYPE; 
    dept employee.workdept%TYPE;
    name employee.firstname%TYPE;  
    phone employee.phoneno%TYPE; 
    phonenum employee.phoneno%TYPE; 
        
CURSOR c1 IS

SELECT 
    empno, workdept, firstname, phoneno, phone(empno)
FROM employee emp
WHERE workdept like 'E%';

BEGIN
    
    OPEN c1;  
    
    LOOP
        FETCH c1 
        INTO 
            empid, dept, name, phone, phonenum;
        EXIT WHEN c1%NOTFOUND;
        UPDATE employee 
            SET phonenum = phonenum 
            WHERE empno = empid;  
        DBMS_OUTPUT.PUT_LINE(dept || ' '||name||' ' || phone || ' ' || phonenum);
        END LOOP;
        CLOSE c1;
        
END;
/
