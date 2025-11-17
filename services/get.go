package services

import (
	"errors"
	"todo/dal"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

func GetAllTodosHandle(c *fiber.Ctx) error {
	var todos []dal.Todo
	res := dal.GetAllTodos(&todos)

	if res.Error != nil {
		return c.Status(500).JSON(fiber.Map{"message": res.Error})
	}

	return c.Status(200).JSON(todos)
}

func GetTodoByIDHandle(c *fiber.Ctx) error {

	todoID := c.Params("todoID")
	data := dal.TodoResponse{}

	res := dal.GetTodoByID(&data, todoID)

	if res.Error != nil {
		if errors.Is(res.Error, gorm.ErrRecordNotFound) {
			return ResponseMessage(c, 404, "Todo not found :/")
		} else {
			return ResponseMessage(c, 500, "Failed to get ToDo")
		}
	}

	return c.Status(200).JSON(data)

}
