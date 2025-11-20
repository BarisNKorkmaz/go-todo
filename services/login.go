package services

import (
	"errors"
	"fmt"
	"todo/dal"
	"todo/jwt"

	"github.com/go-playground/validator/v10"
	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

func LoginHandler(c *fiber.Ctx) error {

	data := new(dal.Auth)

	if err := c.BodyParser(data); err != nil {
		return ResponseMessage(c, 400, "Bad request")
	}

	if err := validate.Struct(data); err != nil {
		var messages []string
		validationErrors := err.(validator.ValidationErrors)

		for _, valErr := range validationErrors {
			messages = append(messages, fmt.Sprintf("Field: %s, failed on: %s, with your value: %s", valErr.Field(), valErr.Tag(), valErr.Value()))
		}
		return c.Status(400).JSON(fiber.Map{
			"messages": "Bad request",
			"Errors":   messages,
		})
	}

	res, user := dal.Login(*data)

	if res.Error != nil {
		if errors.Is(res.Error, gorm.ErrRecordNotFound) {
			return ResponseMessage(c, 401, "Email is not registered")
		}
		return ResponseMessage(c, 500, "failed on log in operations")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(data.Password)); err != nil {
		return ResponseMessage(c, 400, "Wrong password")
	}

	token, err := jwt.GenerateJWT(user.ID)
	if err != nil {
		return ResponseMessage(c, 500, "Failed to generate token")
	}

	return c.Status(200).JSON(fiber.Map{
		"message": "Successfully logged in",
		"token":   token,
	})

}
