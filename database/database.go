package database

import (
	"fmt"

	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var DB *gorm.DB

func Connect() {
	db, err := gorm.Open(sqlite.Open("mydatabase.db"))

	if err != nil {
		fmt.Println("Internal Server Error")
	}

	DB = db

}
