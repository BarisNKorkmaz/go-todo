package services

import (
	"errors"
	"strconv"
	"todo/dal"

	"github.com/gofiber/fiber/v2"
	"gorm.io/gorm"
)

func GetAllTodosHandle(c *fiber.Ctx) error {
	var todos []dal.Todo
	userID := c.Locals("userID").(uint)
	res := dal.GetAllTodos(&todos, userID)

	if res.Error != nil {
		return c.Status(500).JSON(fiber.Map{"message": res.Error})
	}

	return c.Status(200).JSON(todos)
}

func GetTodoByIDHandle(c *fiber.Ctx) error {

	idStr := c.Params("todoID")
	id64, err := strconv.ParseUint(idStr, 10, 64)

	if err != nil {
		return ResponseMessage(c, 400, "wrong formatted id")
	}

	todoID := uint(id64)

	userID := c.Locals("userID").(uint)
	data := dal.TodoResponse{}

	res := dal.GetTodoByID(&data, todoID, userID)

	if res.Error != nil {
		if errors.Is(res.Error, gorm.ErrRecordNotFound) {
			return ResponseMessage(c, 404, "Todo not found :/")
		} else {
			return ResponseMessage(c, 500, "Failed to get ToDo")
		}
	}

	return c.Status(200).JSON(data)

}
