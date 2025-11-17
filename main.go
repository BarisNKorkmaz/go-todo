package main

import (
	"todo/dal"
	"todo/database"
	"todo/services"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

func main() {
	database.Connect()
	database.DB.AutoMigrate(&dal.Todo{})

	app := fiber.New()

	app.Use(cors.New(cors.Config{
		AllowOrigins: "*",
		AllowMethods: "GET,POST,PUT,DELETE,OPTIONS",
		AllowHeaders: "Origin, Content-Type, Accept",
	}))

	app.Post("/todo", services.CreateTodoHandle)
	app.Get("/todo", services.GetAllTodosHandle)
	app.Get("/todo/:todoID", services.GetTodoByIDHandle)
	app.Put("/todo/:todoID", services.UpdateTodoByIDHandle)
	app.Delete("/todo/:todoID", services.DeleteTodoHandle)

	app.Listen(":8080")
}
