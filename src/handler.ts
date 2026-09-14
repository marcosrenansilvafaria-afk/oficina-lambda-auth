import type { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from "aws-lambda";
import { isValidCpf, normalizeCpf } from "./cpf/validate-cpf";
import { findClienteByCpf } from "./db/find-cliente-by-cpf";
import { signAuthToken } from "./jwt/sign-token";

interface AuthRequestBody {
  cpf?: string;
}

function jsonResponse(statusCode: number, body: unknown): APIGatewayProxyResultV2 {
  return {
    statusCode,
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  };
}

export async function handler(
  event: APIGatewayProxyEventV2,
): Promise<APIGatewayProxyResultV2> {
  let requestBody: AuthRequestBody;

  try {
    requestBody = event.body ? (JSON.parse(event.body) as AuthRequestBody) : {};
  } catch {
    return jsonResponse(400, { message: "Corpo da requisicao invalido (JSON esperado)" });
  }

  const rawCpf = requestBody.cpf;

  if (!rawCpf || typeof rawCpf !== "string") {
    return jsonResponse(400, { message: "Campo 'cpf' e obrigatorio" });
  }

  if (!isValidCpf(rawCpf)) {
    return jsonResponse(400, { message: "CPF invalido" });
  }

  const normalizedCpf = normalizeCpf(rawCpf);

  const cliente = await findClienteByCpf(normalizedCpf);

  if (!cliente) {
    return jsonResponse(404, { message: "Cliente nao encontrado" });
  }

  const token = signAuthToken(cliente.id);

  return jsonResponse(200, {
    token,
    cliente: { id: cliente.id, nome: cliente.nome },
  });
}
