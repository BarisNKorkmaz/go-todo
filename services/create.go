package services

import (
	"fmt"
	"time"
	"todo/dal"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
)

var validate = validator.New()

func CreateTodoHandle(c *fiber.Ctx) error {
	data := new(dal.TodoCreate)

	if err := c.BodyParser(data); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": err.Error()})
	}

	if err := validate.Struct(data); err != nil {
		var validationErrors []string

		for _, e := range err.(validator.ValidationErrors) {

			message := fmt.Sprintf("field: %s, failed on: %s, with your value: %s", e.Field(), e.Tag(), e.Value())
			validationErrors = append(validationErrors, message)
		}
		return c.Status(400).JSON(fiber.Map{
			"message": "Bad request",
			"errors":  validationErrors,
		})
	}

	var todo dal.Todo
	todo.Title = data.Title
	todo.Description = data.Description
	todo.DueDate = data.DueDate
	todo.CreatedTime = time.Now()
	todo.UserID = c.Locals("userID").(uint)

	res := dal.CreateTodo(&todo)

	if res.Error != nil {
		return ResponseMessage(c, 500, "Todo create operation failed")
	}

	return ResponseMessage(c, 201, "ToDo successfully created")

}

func ResponseMessage(c *fiber.Ctx, status int, message string) error {
	return c.Status(status).JSON(fiber.Map{"message": message})
}
