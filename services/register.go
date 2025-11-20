package services

import (
	"fmt"
	"strings"
	"todo/dal"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
)

func RegisterHandle(c *fiber.Ctx) error {
	data := new(dal.Auth)
	if err := c.BodyParser(data); err != nil {
		return ResponseMessage(c, 400, "Bad request")
	}

	if err := validate.Struct(data); err != nil {
		validationErr := err.(validator.ValidationErrors)
		var messages []string
		for _, valErr := range validationErr {

			messages = append(messages, fmt.Sprintf("field: %s, failed on: %s, with your value: %s", valErr.Field(), valErr.Tag(), valErr.Value()))
		}
		return c.Status(400).JSON(fiber.Map{
			"message": "Bad request",
			"errors":  messages,
		})
	}

	hashed, err := bcrypt.GenerateFromPassword([]byte(data.Password), 10)
	if err != nil {
		return ResponseMessage(c, 500, "User register operations failed")
	}

	newUser := dal.User{
		Email:    data.Email,
		Password: string(hashed),
	}

	res := dal.CreateUser(&newUser)
	if res.Error != nil {
		if strings.Contains(res.Error.Error(), "UNIQUE") {
			return ResponseMessage(c, 409, "This mail adress already used")
		}
		return ResponseMessage(c, 500, "User register operations failed")
	}

	return ResponseMessage(c, 201, "User registered")

}
