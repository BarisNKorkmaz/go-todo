package dal

import (
	"time"
	"todo/database"

	"gorm.io/gorm"
)

type Todo struct {
	ID            int       `json:"id"`
	Title         string    `json:"title"`
	Description   string    `json:"desc"`
	IsCompleted   bool      `gorm:"default: false"`
	CreatedTime   time.Time `json:"createdTime"`
	CompletedTime time.Time `json:"complitedTime"`
	DueDate       time.Time `json:"dueDate"`
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

func DeleteTodoByID(id any) *gorm.DB {
	return database.DB.Delete(&Todo{}, id)
}

func GetAllTodos(todos *[]Todo) *gorm.DB {
	return database.DB.Find(todos)
}

func GetTodoByID(dest any, id any) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("ID=?", id).First(dest)
}

func UpdateTodoByID(id any, dest any) *gorm.DB {
	return database.DB.Model(&Todo{}).Where("ID=?", id).Updates(dest)
}
