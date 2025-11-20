package dal

import (
	"time"
	"todo/database"

	"gorm.io/gorm"
)

type User struct {
	ID        uint      `gorm:"primaryKey" json:"id"`
	Email     string    `gorm:"unique;not null" json:"email"`
	Password  string    `gorm:"not null" json:"-"`
	CreatedAt time.Time `json:"createdAt"`
	Todos     []Todo    `gorm:"foreignKey:UserID"`
}

type Auth struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
}

func CreateUser(dest *User) *gorm.DB {
	return database.DB.Model(&User{}).Create(dest)
}

func Login(data Auth) (*gorm.DB, User) {
	user := new(User)
	return database.DB.Model(&User{}).Where("email = ?", data.Email).First(user), *user
}
