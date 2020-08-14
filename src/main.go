package main

import (
	"fmt"
	"log"
    "net/http"
    _ "github.com/go-sql-driver/mysql"
    "database/sql"
    "os"
    "html/template"
)

type Employee struct {
	Fname, Dname string
	Id int
}

func helloWorld(w http.ResponseWriter, r *http.Request){
    name, err := os.Hostname()
    checkErr(err)
    fmt.Fprintf(w, "HOSTNAME : %s\n", name)
}

func dbConnect() (db *sql.DB) {
    dbDriver := "mysql"
	dbHost := os.Getenv("DB_HOST")
	if dbHost == "" {
		dbHost = "127.0.0.1"
	}

	dbPort := os.Getenv("DB_PORT")
	if dbPort == "" {
		dbPort = "3306"
	}

	dbUser, ok := os.LookupEnv("DB_USERNAME")
	if !ok || dbUser == "" {
		log.Fatal("DB_USERNAME not specified")
	}

	dbPass, ok := os.LookupEnv("DB_PASSWORD")
	if !ok || dbPass == "" {
		log.Fatal("DB_PASSWORD not specified")
	}

	dbName := os.Getenv("DB_NAME")
	if dbName == "" {
		dbName = "test"
	}

    db, err := sql.Open(dbDriver, dbUser +":"+ dbPass +"@tcp("+ dbHost +":"+ dbPort +")/"+ dbName)

    checkErr(err)
    return db
}

func dbSelect() []Employee{
    db := dbConnect()
    rows, err := db.Query("select * from employee")
    checkErr(err)

    employee := Employee{}
    employees := []Employee{}

    for rows.Next() {
		var first_name, department string
		var id int
        err = rows.Scan(&id, &first_name, &department)
        checkErr(err)
        employee.Id = id
        employee.Fname = first_name
        employee.Dname = department
        employees = append(employees, employee)

    }
    defer db.Close()
    return employees
}

var tmpl = template.Must(template.ParseFiles("./src/static/layout.html"))
//var tmpl = template.Must(template.ParseGlob("layout.html"))
func dbTableHtml(w http.ResponseWriter, r *http.Request){
    table := dbSelect()
    tmpl.ExecuteTemplate(w, "Index", table)
}

func dbTable(w http.ResponseWriter, r *http.Request){
    table := dbSelect()
    for i := range(table) {
        emp := table[i]
        fmt.Fprintf(w,"YESS|%12s|%12s|%12s|\n" ,emp.Id, emp.Fname ,emp.Dname)
    }
}

func main() {
    http.HandleFunc("/", helloWorld)
    http.HandleFunc("/view", dbTableHtml) 
    http.HandleFunc("/raw", dbTable)
    http.ListenAndServe(":8080", nil)
}

func checkErr(err error) {
    if err != nil {
        panic(err)
    }
}