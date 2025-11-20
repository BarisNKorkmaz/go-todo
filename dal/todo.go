package dal

import (
	"time"
	"todo/database"

	"gorm.io/gorm"
)

type Todo struct {
	ID            int       `gorm:"primaryKey" json:"id"`
	Title         string    `json:"title"`
	Description   string    `json:"desc"`
	IsCompleted   bool      `gorm:"default: false" json:"isCompleted"`
	CreatedTime   time.Time `json:"createdTime"`
	CompletedTime time.Time `json:"completedTime"`
	DueDate       time.Time `json:"dueDate"`
	UserID        uint      `json:"UserID"`
}

type TodoCreate struct {
	Title       string    `json:"title" validate:"required,max=50"`
	Description string    `json:"desc" validate:"required,min=3,max=200"`
	DueDate     time.Time `json:"dueDate"`
}

type TodoUpdate struct {
	Title       string    `json:"title" validate:"max=50"`
	Description string    `json:"desc" validate:"max=200"`
	DueDate     time.Time `json:"dueDate"`
	IsCompleted bool      `json:"isCompleted"`
}

type TodoMakeCompleted struct {
	IsCompleted   bool
	CompletedTime time.Time
}

type TodoResponse struct {
	ID            uint      `json:"id"`
	Title         string    `json:"title"`
	Description   string    `json:"desc"`
	DueDate       time.Time `json:"dueDate"`
	CreatedTime   time.Time `json:"createdTime"`
	IsCompleted   bool      `json:"isCompleted"`
	CompletedTime time.Time `json:"completedTime"`
}

func CreateTodo(dest *Todo) *gorm.DB {
	return database.DB.Model(&Todo{}).Create(dest)
}

func DeleteTodoByID(todoID uint, userID uint) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("id = ? AND user_id = ?", todoID, userID).Delete(&Todo{})
}

func GetAllTodos(todos *[]Todo, userID uint) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("user_id = ?", userID).Find(todos)
}

func GetTodoByID(dest any, todoID uint, userID uint) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("ID= ? AND user_id = ?", todoID, userID).First(dest)
}

func UpdateTodoByID(dest any, todoID uint, userID uint) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("ID= ? AND user_id= ?", todoID, userID).Updates(dest)
}
