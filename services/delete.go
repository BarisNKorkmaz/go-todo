package services

import (
	"strconv"
	"todo/dal"

	"github.com/gofiber/fiber/v2"
)

func DeleteTodoHandle(c *fiber.Ctx) error {

	idStr := c.Params("todoID")
	id64, err := strconv.ParseUint(idStr, 10, 64)

	if err != nil {
		return ResponseMessage(c, 400, "wrong formatted id")
	}
	todoID := uint(id64)

	userID := c.Locals("userID").(uint)
	res := dal.DeleteTodoByID(todoID, userID)

	if res.Error != nil || res.RowsAffected == 0 {
		return ResponseMessage(c, 500, "Todo Deleting operation is failed")
	}

	return ResponseMessage(c, 200, "ToDo successfully deleted")

}
