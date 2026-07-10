import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { TaskRepository, TaskInfo, TaskRecord, Logger } from 'common';

export default class FormAbility extends FormExtensionAbility {
  private initialized: boolean = false;

  private async ensureInit(): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      await TaskRepository.getInstance().init(this.context);
      this.initialized = true;
      Logger.info('FormAbility Repository init done');
    } catch (e) {
      Logger.error('FormAbility Repository init failed');
    }
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info('FormAbility onAddForm');
    const emptyData: Record<string, string> = {};
    void this.ensureInit().then(() => {
      const formId: string = this.extractFormId(want);
      if (formId.length > 0) {
        void this.updateFormById(formId);
      }
    });
    return formBindingData.createFormBindingData(emptyData);
  }

  onUpdateForm(formId: string): void {
    Logger.info(`FormAbility onUpdateForm formId=${formId}`);
    void this.ensureInit().then(async () => {
      try {
        await TaskRepository.getInstance().maybeRollOverDate();
      } catch (e) {
        Logger.error('FormAbility maybeRollOverDate failed');
      }
      await this.updateFormById(formId);
    });
  }

  onCastToNormalForm(formId: string): void {
    Logger.info(`FormAbility onCastToNormalForm formId=${formId}`);
  }

  onFormEvent(formId: string, message: string): void {
    Logger.info(`FormAbility onFormEvent formId=${formId} message=${message}`);
  }

  onRemoveForm(formId: string): void {
    Logger.info(`FormAbility onRemoveForm formId=${formId}`);
  }

  private extractFormId(want: Want): string {
    if (!want.parameters) {
      return '';
    }
    const val: Object = want.parameters[formInfo.FormParam.IDENTITY_KEY];
    if (typeof val === 'string') {
      return val;
    }
    return '';
  }

  private async updateFormById(formId: string): Promise<void> {
    const formData: Record<string, string> = await this.buildFormData();
    const bindingData: formBindingData.FormBindingData =
      formBindingData.createFormBindingData(formData);
    formProvider.updateForm(formId, bindingData).then(() => {
      Logger.info(`FormAbility updateForm success formId=${formId}`);
    }).catch((error: BusinessError) => {
      Logger.error(`FormAbility updateForm failed code=${error.code}`);
    });
  }

  private async buildFormData(): Promise<Record<string, string>> {
    const data: Record<string, string> = {};
    try {
      const tasks: TaskInfo[] = await TaskRepository.getInstance().getTasks();
      const records: TaskRecord[] = await TaskRepository.getInstance().getTodayRecords();
      const openTasks: TaskInfo[] = [];
      for (const t of tasks) {
        if (t.isOpen) {
          openTasks.push(t);
        }
      }
      data['taskCount'] = openTasks.length.toString();
      for (let i: number = 0; i < openTasks.length && i < 6; i++) {
        const task: TaskInfo = openTasks[i];
        const prefix: string = `task${i}`;
        data[`${prefix}Type`] = task.taskType.toString();
        let finNum: number = 0;
        let targetValue: number = task.targetValue;
        let isDone: boolean = false;
        for (const r of records) {
          if (r.taskType === task.taskType) {
            finNum = r.finNum;
            targetValue = r.targetValue;
            isDone = r.isDone;
            break;
          }
        }
        data[`${prefix}Done`] = isDone ? '1' : '0';
        data[`${prefix}Fin`] = finNum.toString();
        data[`${prefix}Target`] = targetValue.toString();
      }
      let doneCount: number = 0;
      for (const r of records) {
        if (r.isDone) {
          doneCount++;
        }
      }
      const totalCount: number = openTasks.length;
      const progress: number = totalCount === 0 ? 0 : Math.floor(doneCount * 100 / totalCount);
      data['progress'] = progress.toString();
      data['doneCount'] = doneCount.toString();
      data['totalCount'] = totalCount.toString();
      data['hasTasks'] = totalCount > 0 ? '1' : '0';
      Logger.info(`FormAbility buildFormData taskCount=${totalCount} progress=${progress}`);
    } catch (e) {
      Logger.error('FormAbility buildFormData failed');
      data['taskCount'] = '0';
      data['progress'] = '0';
      data['doneCount'] = '0';
      data['totalCount'] = '0';
      data['hasTasks'] = '0';
    }
    return data;
  }
}
