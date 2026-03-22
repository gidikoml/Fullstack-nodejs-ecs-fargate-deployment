import { render, screen, waitFor } from "@testing-library/react";
import axios from "axios";
import App from "./App";

jest.mock("axios");

test("renders the bookstore dashboard and support entry point", async () => {
  axios.get.mockResolvedValue({
    data: [
      {
        id: 1,
        title: "AWS Fundamentals",
        desc: "Cloud basics for engineers",
        price: 29.99,
        cover: "https://example.com/aws-book.jpg",
      },
    ],
  });

  render(<App />);

  expect(await screen.findByText(/explore the best selling books/i)).toBeInTheDocument();
  expect(screen.getByText(/modern bookstore dashboard for real buyers/i)).toBeInTheDocument();
  expect(screen.getByRole("button", { name: /open support bot/i })).toBeInTheDocument();

  await waitFor(() => {
    expect(axios.get).toHaveBeenCalledWith("http://aluru.site/books");
  });
});
