namespace MyTemplate;

internal static class Program
{
	internal static void Main(string[] args)
	{
		var builder = WebApplication.CreateBuilder(args);

		// Services
		// builder.Services.AddControllers(); // MVC
		// builder.Services.AddSignalR();
		// builder.Services.AddOpenApi();
		builder.Services.AddEndpointsApiExplorer(); // needed for minimal APIs
		builder.Services.AddSwaggerGen();

		builder.WebHost.ConfigureKestrel(static serverOptions => serverOptions.AddServerHeader = false);

		var app = builder.Build();

		app.UseHttpsRedirection();

		if (app.Environment.IsDevelopment())
		{
			// app.MapOpenApi(); // /openapi/v1.json
			app.UseSwagger(); // /swagger/v1/swagger.json
			app.UseSwaggerUI(); // /swagger/index.html
		}

		app.MapGet("/", static () => "Hello World!");
		app.MapGet("/json", static () =>
		{
			var response = new
			{
				message = "Hello World!",
				status = "success",
			};

			return response;
		});

		// app.MapControllers(); // MVC

		app.Run();
	}
}
