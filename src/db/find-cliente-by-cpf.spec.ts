const queryMock = jest.fn();

jest.mock("pg", () => ({
  Pool: jest.fn().mockImplementation(() => ({
    query: queryMock,
  })),
}));

import { findClienteByCpf } from "./find-cliente-by-cpf";

describe("findClienteByCpf", () => {
  beforeEach(() => {
    queryMock.mockReset();
    process.env.DB_HOST = "localhost";
    process.env.DB_PORT = "5432";
    process.env.DB_NAME = "oficina";
    process.env.DB_USER = "oficina_admin";
    process.env.DB_PASSWORD = "test-password";
  });

  it("retorna o cliente quando encontrado", async () => {
    queryMock.mockResolvedValueOnce({
      rows: [{ id: "cliente-uuid-123", nome: "Maria Silva" }],
    });

    const cliente = await findClienteByCpf("11144477735");

    expect(cliente).toEqual({ id: "cliente-uuid-123", nome: "Maria Silva" });
    expect(queryMock).toHaveBeenCalledWith(
      "SELECT id, nome FROM clientes WHERE documento = $1 LIMIT 1",
      ["11144477735"],
    );
  });

  it("retorna null quando nao encontrado", async () => {
    queryMock.mockResolvedValueOnce({ rows: [] });

    const cliente = await findClienteByCpf("00000000000");

    expect(cliente).toBeNull();
  });
});
