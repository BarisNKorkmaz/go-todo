package services

import (
	"fmt"
	"strconv"
	"time"
	"todo/dal"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

func UpdateTodoByIDHandle(c *fiber.Ctx) error {
	idStr := c.Params("todoID")
	id64, err := strconv.ParseUint(idStr, 10, 64)
	if err != nil {
		return ResponseMessage(c, 400, "wrong formatted id")
	}
	todoID := uint(id64)

	userID := c.Locals("userID").(uint)
	data := new(dal.TodoUpdate)

	if err := c.BodyParser(data); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": err.Error()})
	}

	if err := validate.Struct(data); err != nil {
		var message []string
		validationErrors := err.(validator.ValidationErrors)

		for _, validationErr := range validationErrors {
			message = append(message, fmt.Sprintf("Field: %s, failed on: %s, with your value: %s", validationErr.Field(), validationErr.Tag(), validationErr.Value()))
		}
		return c.Status(400).JSON(fiber.Map{
			"message": "Bad request",
			"errors":  message,
		})
	}

	doCompleted(todoID, userID, data)

	res := dal.UpdateTodoByID(data, todoID, userID)

	if res.Error != nil || res.RowsAffected == 0 {
		return ResponseMessage(c, 500, "Todo update failed")
	}

	return ResponseMessage(c, 200, "todo successfully updated")

}

func doCompleted(todoID uint, userID uint, data *dal.TodoUpdate) {

	oldData := new(dal.TodoResponse)
	newData := new(dal.TodoMakeCompleted)

	res := dal.GetTodoByID(oldData, todoID, userID)

	if res.Error != nil {
		fmt.Println("has an error on getting old data")
	}

	if oldData.IsCompleted != data.IsCompleted {
		newData.IsCompleted = true
		newData.CompletedTime = time.Now()
	}

	updateRes := dal.UpdateTodoByID(newData, todoID, userID)

	if updateRes.Error != nil {
		fmt.Println("has an error on updating")
	}
}
