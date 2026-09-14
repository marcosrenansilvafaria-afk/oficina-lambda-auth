import jwt from "jsonwebtoken";

export interface AuthTokenPayload {
  sub: string;
  role: "CLIENTE";
}

/**
 * Formato do payload alinhado ao que o app principal (Repositorio 3) ja
 * espera em src/auth/jwt.strategy.ts: { sub: string; role: Role }.
 * O valor "CLIENTE" ainda nao existe no enum Role do app principal - precisa
 * ser adicionado la para o token ser aceito nas rotas protegidas.
 */
export function signAuthToken(clienteId: string): string {
  const secret = process.env.JWT_SECRET;
  if (!secret) {
    throw new Error("JWT_SECRET nao configurado");
  }

  const payload: AuthTokenPayload = {
    sub: clienteId,
    role: "CLIENTE",
  };

  const expiresIn = process.env.JWT_EXPIRES_IN ?? "1h";

  return jwt.sign(payload, secret, {
    algorithm: "HS256",
    expiresIn,
  } as jwt.SignOptions);
}
