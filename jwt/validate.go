package jwt

import (
	"fmt"
	"strings"

	"github.com/gofiber/fiber/v2"
)

func ValidateJWT(c *fiber.Ctx) error {

	authHeader := c.Get("Authorization")

	if authHeader == "" {
		return c.Status(401).JSON(fiber.Map{
			"message": "Missing Authorization header",
		})
	}

	parts := strings.SplitN(authHeader, " ", 2)
	if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
		return c.Status(401).JSON(fiber.Map{
			"message": "Invalid Authorization header format",
		})
	}
	fmt.Println(authHeader)
	fmt.Println("------------------------------------------------------------------------")
	fmt.Println(parts)

	tokenStr := parts[1]
	userId, err := ParseJWT(tokenStr)

	if err != nil {
		return c.Status(401).JSON(fiber.Map{
			"message": "Invalid or expired token",
		})
	}

	c.Locals("userID", userId)

	return c.Next()

}
