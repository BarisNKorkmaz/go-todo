package services

import (
	"todo/dal"

	"github.com/gofiber/fiber/v2"
)

func DeleteTodoHandle(c *fiber.Ctx) error {

	todoID := c.Params("todoID")
	res := dal.DeleteTodoByID(todoID)

	if res.Error != nil || res.RowsAffected == 0 {
		return ResponseMessage(c, 500, "Todo Deleting operation is failed")
	}

	return ResponseMessage(c, 200, "ToDo successfully deleted")

}
