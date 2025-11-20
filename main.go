package main

import (
	"todo/dal"
	"todo/database"
	"todo/jwt"
	"todo/services"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

func main() {
	database.Connect()
	database.DB.AutoMigrate(&dal.Todo{}, &dal.User{})

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin, Content-Type, Accept, Authorization",
	}))

	app.Use("/todo", jwt.ValidateJWT)

	app.Post("/todo", services.CreateTodoHandle)
	app.Get("/todo", services.GetAllTodosHandle)
	app.Get("/todo/:todoID", services.GetTodoByIDHandle)
	app.Put("/todo/:todoID", services.UpdateTodoByIDHandle)
	app.Delete("/todo/:todoID", services.DeleteTodoHandle)

	app.Post("/auth/register", services.RegisterHandle)
	app.Post("/auth/login", services.LoginHandler)

	app.Listen(":8080")
}
