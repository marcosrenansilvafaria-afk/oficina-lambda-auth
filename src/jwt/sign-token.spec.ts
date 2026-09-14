import jwt from "jsonwebtoken";
import { signAuthToken } from "./sign-token";

describe("signAuthToken", () => {
  const originalSecret = process.env.JWT_SECRET;
  const originalExpiresIn = process.env.JWT_EXPIRES_IN;

  afterEach(() => {
    process.env.JWT_SECRET = originalSecret;
    process.env.JWT_EXPIRES_IN = originalExpiresIn;
  });

  it("gera um token valido com sub e role=CLIENTE", () => {
    process.env.JWT_SECRET = "test-secret";
    delete process.env.JWT_EXPIRES_IN;

    const token = signAuthToken("cliente-uuid-123");
    const decoded = jwt.verify(token, "test-secret") as jwt.JwtPayload;

    expect(decoded.sub).toBe("cliente-uuid-123");
    expect(decoded.role).toBe("CLIENTE");
  });

  it("respeita JWT_EXPIRES_IN quando configurado", () => {
    process.env.JWT_SECRET = "test-secret";
    process.env.JWT_EXPIRES_IN = "5m";

    const token = signAuthToken("cliente-uuid-456");
    const decoded = jwt.verify(token, "test-secret") as jwt.JwtPayload;

    expect(decoded.exp).toBeDefined();
    expect(decoded.iat).toBeDefined();
    expect((decoded.exp as number) - (decoded.iat as number)).toBe(5 * 60);
  });

  it("lanca erro se JWT_SECRET nao estiver configurado", () => {
    delete process.env.JWT_SECRET;
    expect(() => signAuthToken("cliente-uuid-789")).toThrow("JWT_SECRET nao configurado");
  });
});
