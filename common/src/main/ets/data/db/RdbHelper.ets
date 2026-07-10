import { relationalStore } from '@kit.ArkData';
import { RdbTables } from './RdbTables';
import { Constants } from '../../common/Constants';
import { Logger } from '../../common/Logger';

export class RdbHelper {
  private static instance: RdbHelper | null = null;
  private store: relationalStore.RdbStore | null = null;

  public static getInstance(): RdbHelper {
    if (RdbHelper.instance === null) {
      RdbHelper.instance = new RdbHelper();
    }
    return RdbHelper.instance;
  }

  public async getStore(context: Context): Promise<relationalStore.RdbStore> {
    if (this.store !== null) {
      return this.store;
    }
    const config: relationalStore.StoreConfig = {
      name: Constants.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    this.store = await relationalStore.getRdbStore(context, config);
    await this.store.executeSql(RdbTables.CREATE_TASK_SQL);
    await this.store.executeSql(RdbTables.CREATE_TASK_RECORD_SQL);
    await this.store.executeSql(RdbTables.CREATE_INDEX_SQL);
    await this.store.executeSql(RdbTables.SEED_TASKS_SQL);
    await this.migrateSmileBrushToMulti();
    Logger.info('RdbHelper initialized');
    return this.store;
  }

  private async migrateSmileBrushToMulti(): Promise<void> {
    if (this.store === null) {
      return;
    }
    await this.store.executeSql(
      'UPDATE task SET flag = 1 WHERE taskType IN (3, 4) AND flag = 0'
    );
  }

  public getRdbStore(): relationalStore.RdbStore | null {
    return this.store;
  }
}
