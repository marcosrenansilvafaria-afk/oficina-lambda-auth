import { Pool } from "pg";

export interface Cliente {
  id: string;
  nome: string;
}

let pool: Pool | undefined;

function getPool(): Pool {
  if (!pool) {
    pool = new Pool({
      host: process.env.DB_HOST,
      port: Number(process.env.DB_PORT ?? 5432),
      database: process.env.DB_NAME,
      user: process.env.DB_USER,
      password: process.env.DB_PASSWORD,
      ssl: { rejectUnauthorized: false },
      max: 1,
      idleTimeoutMillis: 0,
    });
  }
  return pool;
}

/**
 * Busca um cliente pelo CPF/CNPJ (coluna `documento` na tabela `clientes`,
 * conforme schema Prisma do app principal - model Cliente @@map("clientes")).
 */
export async function findClienteByCpf(normalizedCpf: string): Promise<Cliente | null> {
  const result = await getPool().query<Cliente>(
    "SELECT id, nome FROM clientes WHERE documento = $1 LIMIT 1",
    [normalizedCpf],
  );

  return result.rows[0] ?? null;
}
